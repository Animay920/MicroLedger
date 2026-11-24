const Redis = require("ioredis");

const redisUrl = process.env.REDIS_URL || "redis://127.0.0.1:6379";

const redis = new Redis(redisUrl, {
  maxRetriesPerRequest: 1,
  enableReadyCheck: false,
  lazyConnect: true,
  retryStrategy(times) {
    if (times > 3) return null; // stop reconnecting if Redis is unavailable
    return Math.min(times * 1000, 3000);
  }
});

redis.connect().catch(() => {
  // Gracefully fallback to PostgreSQL transactional idempotency guards
});

redis.on("error", () => {
  // Silent fallback: ensures application continues serving via PostgreSQL fallback
});

module.exports = redis;
