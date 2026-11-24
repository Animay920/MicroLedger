const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const htmlPath = path.resolve(__dirname, '../MicroLedger_Technical_Documentation_and_Schema_Whitepaper.html');
const pdfPath = path.resolve(__dirname, '../MicroLedger_Technical_Documentation_and_Schema_Whitepaper.pdf');

console.log('Rendering PDF from:', htmlPath);
const edgePath = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const fileUrl = 'file:///' + htmlPath.replace(/\\/g, '/');

execSync(`"${edgePath}" --headless=new --disable-gpu --no-pdf-header-footer --run-all-compositor-stages-before-draw --print-to-pdf="${pdfPath}" "${fileUrl}"`);

const stats = fs.statSync(pdfPath);
console.log('PDF Generated Successfully!');
console.log('PDF Path:', pdfPath);
console.log('Size:', (stats.size / 1024).toFixed(1), 'KB');
