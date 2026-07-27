
/**
 * datagrid-config.js - Data configuration separated from core logic
 * This file contains ONLY data-specific configuration for Team Directory
 * Core DataGrid logic lives in datagrid.js
 * Data itself lives in employees.json
 */

// Helpers - specific to this dataset but reusable pattern
function getAvatarClass(name) {
  const h = [...name].reduce((a,c)=>a+c.charCodeAt(0),0);
  const variants = ['avatar-blue','avatar-amber'];
  return variants[h%variants.length];
}
function getStatusMeta(status) {
  if(status==='Active') return {cls:'status-active', tooltip:'Active - Currently working'};
  if(status==='On Leave') return {cls:'status-leave', tooltip:'On Leave - Temporarily away'};
  return {cls:'', style:'background:var(--dg-surface-2); color:var(--dg-text-soft); border-color:var(--dg-border);', tooltip:'Inactive'};
}

// Column definitions - separated from core, reusable for any table
const teamDirectoryColumns = [
  {
    key: 'id',
    label: 'ID',
    sortable: true,
    width: '90px',
    className: 'cell-id',
    tooltip: (v) => `Employee ID: ${v} | Click to copy`,
    render: (v) => `#${v}`
  },
  {
    key: 'name',
    label: 'Name',
    sortable: true,
    className: 'cell-name',
    render: (v, row) => {
      const initials = row.initials || v.split(' ').map(n=>n[0]).join('').substring(0,2).toUpperCase();
      return `<div class="name-stack"><span class="avatar ${getAvatarClass(v)}" data-tooltip="${v} • ${row.dept||''}">${initials}</span><span class="name-text" data-tooltip="${v} - ${row.email||''}">${v}</span></div>`;
    }
  },
  {
    key: 'role',
    label: 'Role',
    sortable: true,
    className: 'cell-role',
    tooltip: (v, row) => `Role: ${v} • Dept: ${row.dept||''}`,
    render: (v) => v||''
  },
  {
    key: 'status',
    label: 'Status',
    sortable: true,
    className: 'cell-status',
    render: (v) => {
      const meta = getStatusMeta(v);
      const style = meta.style ? `style="${meta.style}"` : '';
      return `<span class="status-badge ${meta.cls}" ${style} data-tooltip="${meta.tooltip}"><span class="dot"></span> ${v}</span>`;
    }
  }
];

// Detail renderer - separated from core
function teamDetailRenderer(row) {
  const chips = (arr) => Array.isArray(arr) ? arr.map(x=>`<span class="chip">${x}</span>`).join('') : `<span class="chip">${arr||''}</span>`;
  return `
    <div class="detail-grid">
      <div class="detail-item"><label>Email</label><div class="value">${row.email||''}</div></div>
      <div class="detail-item"><label>Department</label><div class="value">${row.dept||''}</div></div>
      <div class="detail-item"><label>Location</label><div class="value">${row.location||''}</div></div>
      <div class="detail-item"><label>Projects</label><div class="value">${chips(row.projects)}</div></div>
    </div>
  `;
}

// CRUD handlers - data manipulation separated from UI core
let currentEditId = null;
let currentDeleteId = null;

function openAddModal(grid) {
  document.getElementById('addRecordForm')?.reset();
  const modal = document.getElementById('addRecordModal');
  if (modal && window.bootstrap) new bootstrap.Modal(modal).show();
}

function openEditModal(rowData, grid) {
  if (!rowData) return;
  currentEditId = rowData.id;
  document.getElementById('editRecordId').value = rowData.id;
  document.getElementById('editRecordName').value = rowData.name||'';
  document.getElementById('editRecordRole').value = rowData.role||'';
  document.getElementById('editRecordStatus').value = rowData.status||'Active';
  document.getElementById('editRecordEmail').value = rowData.email||'';
  document.getElementById('editRecordDept').value = rowData.dept||'';
  document.getElementById('editRecordLocation').value = rowData.location||'';
  document.getElementById('editRecordProjects').value = Array.isArray(rowData.projects) ? rowData.projects.join(', ') : (rowData.projects||'');
  const modal = document.getElementById('editRecordModal');
  if (modal && window.bootstrap) new bootstrap.Modal(modal).show();
}

function openDeleteModal(rowData, grid) {
  if (!rowData) return;
  currentDeleteId = rowData.id;
  document.getElementById('deleteTargetName').textContent = `${rowData.name} (#${rowData.id})`;
  const modal = document.getElementById('deleteRecordModal');
  if (modal && window.bootstrap) new bootstrap.Modal(modal).show();
}

function handleAddSubmit(e, grid) {
  e.preventDefault();
  const id = document.getElementById('addRecordId').value.trim();
  const name = document.getElementById('addRecordName').value.trim();
  const role = document.getElementById('addRecordRole').value.trim();
  const status = document.getElementById('addRecordStatus').value;
  const email = document.getElementById('addRecordEmail').value.trim();
  const dept = document.getElementById('addRecordDept').value.trim()||'General';
  const location = document.getElementById('addRecordLocation').value.trim()||'Remote';
  const projectsRaw = document.getElementById('addRecordProjects').value.trim();
  const projects = projectsRaw ? projectsRaw.split(',').map(s=>s.trim()).filter(Boolean) : [];
  const initials = name.split(' ').map(n=>n[0]).join('').substring(0,2).toUpperCase();
  const newRow = { id: isNaN(id)?id:Number(id)||id, name, initials, role, status, email, dept, location, projects };
  grid.addRow(newRow);
  bootstrap.Modal.getInstance(document.getElementById('addRecordModal'))?.hide();
}

function handleEditSubmit(e, grid) {
  e.preventDefault();
  if (!currentEditId) return;
  const name = document.getElementById('editRecordName').value.trim();
  const role = document.getElementById('editRecordRole').value.trim();
  const status = document.getElementById('editRecordStatus').value;
  const email = document.getElementById('editRecordEmail').value.trim();
  const dept = document.getElementById('editRecordDept').value.trim();
  const location = document.getElementById('editRecordLocation').value.trim();
  const projectsRaw = document.getElementById('editRecordProjects').value.trim();
  const projects = projectsRaw ? projectsRaw.split(',').map(s=>s.trim()).filter(Boolean) : [];
  const initials = name.split(' ').map(n=>n[0]).join('').substring(0,2).toUpperCase();
  grid.updateRow(currentEditId, { name, initials, role, status, email, dept, location, projects });
  bootstrap.Modal.getInstance(document.getElementById('editRecordModal'))?.hide();
  currentEditId = null;
}

function handleDeleteConfirm(grid) {
  if (!currentDeleteId) return;
  grid.deleteRow(currentDeleteId);
  bootstrap.Modal.getInstance(document.getElementById('deleteRecordModal'))?.hide();
  currentDeleteId = null;
}

// Export config - this is the data portion separated from core logic
const teamDirectoryConfig = {
  dataUrl: './employees.json',
  columns: teamDirectoryColumns,
  detailRenderer: teamDetailRenderer,
  idField: 'id',
  pageSize: 5,
  pageSizeOptions: [2,5,10,25],
  searchableFields: ['id','name','role','status','email','dept','location'],
  filterableFields: ['id','name','role','status','dept','location'],
  cacheKey: 'dg-team-directory',
  title: 'Team Directory',
  description: '48 rows via employees.json • Flat • Light/Dark • Reusable DataGrid library',
  selectable: true,
  expandable: true,
  stickyFirst: false,
  tooltips: true,
  contextMenu: true,
  mobileCards: true,
  aria: true,
  onAdd: openAddModal,
  onEdit: openEditModal,
  onDelete: openDeleteModal,
};

// For other tables, just define different columns and dataUrl
// Example:
// const productConfig = {
//   dataUrl: './products.json',
//   columns: [{key:'sku', label:'SKU'}, {key:'name', label:'Product'}, ...],
//   idField: 'sku',
//   pageSize: 10
// };
