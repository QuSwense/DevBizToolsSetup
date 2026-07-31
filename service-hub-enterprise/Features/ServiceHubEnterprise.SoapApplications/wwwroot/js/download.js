// Downloads text content as a file via a client-side blob (used for CSV/JSON export).
export function downloadTextFile(content, fileName, mimeType) {
    const blob = new Blob([content], { type: `${mimeType || 'text/plain'};charset=utf-8` });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
}
