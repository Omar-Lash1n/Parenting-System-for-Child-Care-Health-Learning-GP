// ═══════════════════════════════════════════════════════════
// أجيال — Specialist Admin Dashboard — app.js
// ═══════════════════════════════════════════════════════════

const API_BASE =
  'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

let allSpecialists = [];
let currentFilter = 'all';
let selectedSpecialistId = null; // for reject flow

// ─── Initialize ───────────────────────────────────────────

// Fetch directly on load
document.addEventListener('DOMContentLoaded', () => {
  fetchSpecialists();
});

// ─── Fetch Specialists ────────────────────────────────────

async function fetchSpecialists() {
  const loading = document.getElementById('loading');
  const tableBody = document.getElementById('tableBody');
  const emptyState = document.getElementById('emptyState');
  const table = document.getElementById('specialistsTable');

  loading.style.display = 'block';
  table.style.display = 'none';
  emptyState.style.display = 'none';

  try {
    const res = await fetch(`${API_BASE}/Specialist`, {
      headers: {
        accept: 'application/json',
      },
    });

    if (res.status === 401) {
      showToast('لم يتم التحقق من الصلاحيات (401 Unauthorized)', 'error');
      loading.style.display = 'none';
      return;
    }

    const data = await res.json();

    if (data.success && Array.isArray(data.data)) {
      allSpecialists = data.data;
    } else {
      allSpecialists = [];
    }

    updateStats();
    renderTable();
  } catch (err) {
    console.error('Fetch error:', err);
    showToast('فشل الاتصال بالسيرفر.', 'error');
  } finally {
    loading.style.display = 'none';
  }
}

// ─── Stats ────────────────────────────────────────────────

function updateStats() {
  const pending = allSpecialists.filter((s) => s.status === 'Pending').length;
  const approved = allSpecialists.filter((s) => s.status === 'Approved').length;
  const rejected = allSpecialists.filter((s) => s.status === 'Rejected').length;

  document.getElementById('pendingCount').textContent = pending;
  document.getElementById('approvedCount').textContent = approved;
  document.getElementById('rejectedCount').textContent = rejected;
}

// ─── Filter ───────────────────────────────────────────────

function filterByStatus(status) {
  currentFilter = status;

  // Update tab UI
  document.querySelectorAll('.filter-tab').forEach((tab) => {
    tab.classList.toggle('active', tab.dataset.filter === status);
  });

  renderTable();
}

// ─── Render Table ─────────────────────────────────────────

function renderTable() {
  const tableBody = document.getElementById('tableBody');
  const table = document.getElementById('specialistsTable');
  const emptyState = document.getElementById('emptyState');

  const filtered =
    currentFilter === 'all'
      ? allSpecialists
      : allSpecialists.filter((s) => s.status === currentFilter);

  if (filtered.length === 0) {
    table.style.display = 'none';
    emptyState.style.display = 'block';
    return;
  }

  table.style.display = 'table';
  emptyState.style.display = 'none';

  tableBody.innerHTML = filtered
    .map(
      (s, i) => `
    <tr>
      <td>${i + 1}</td>
      <td>
        ${
          s.personalPhotoUrl
            ? `<img class="table-avatar" src="${s.personalPhotoUrl}" alt="${s.fullName}" onerror="this.outerHTML='<div class=\\'table-avatar-placeholder\\'>👤</div>'">`
            : '<div class="table-avatar-placeholder">👤</div>'
        }
      </td>
      <td><span class="name-link" onclick="openDetail('${s.specialistId}')">${s.fullName || '—'}</span></td>
      <td>${s.specialization || '—'}</td>
      <td>${formatDate(s.createdAt)}</td>
      <td>${statusBadge(s.status)}</td>
      <td>
        <div class="table-actions">
          <button class="btn btn-sm btn-outline" onclick="openDetail('${s.specialistId}')">عرض</button>
          ${
            s.status === 'Pending'
              ? `
            <button class="btn btn-sm btn-success" onclick="approveSpecialist('${s.specialistId}')">قبول</button>
            <button class="btn btn-sm btn-danger" onclick="openRejectModal('${s.specialistId}')">رفض</button>
          `
              : ''
          }
        </div>
      </td>
    </tr>
  `
    )
    .join('');
}

// ─── Helpers ──────────────────────────────────────────────

function statusBadge(status) {
  const map = {
    Pending: { label: 'قيد المراجعة', cls: 'pending' },
    Approved: { label: 'مقبول', cls: 'approved' },
    Rejected: { label: 'مرفوض', cls: 'rejected' },
  };
  const s = map[status] || { label: status, cls: 'pending' };
  return `<span class="status-badge ${s.cls}">${s.label}</span>`;
}

function formatDate(dateStr) {
  if (!dateStr) return '—';
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString('ar-EG', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  } catch {
    return dateStr;
  }
}

// ─── Detail Modal ─────────────────────────────────────────

function openDetail(id) {
  const s = allSpecialists.find((x) => x.specialistId === id);
  if (!s) return;

  const modal = document.getElementById('detailModal');
  const body = document.getElementById('modalBody');
  const footer = document.getElementById('modalFooter');

  body.innerHTML = `
    <div class="detail-grid">
      <div class="detail-field">
        <span class="detail-label">الاسم الكامل</span>
        <span class="detail-value">${s.fullName || '—'}</span>
      </div>
      <div class="detail-field">
        <span class="detail-label">التخصص</span>
        <span class="detail-value">${s.specialization || '—'}</span>
      </div>
      <div class="detail-field">
        <span class="detail-label">الحالة</span>
        <span class="detail-value">${statusBadge(s.status)}</span>
      </div>
      <div class="detail-field">
        <span class="detail-label">تاريخ التسجيل</span>
        <span class="detail-value">${formatDate(s.createdAt)}</span>
      </div>
    </div>

    <div class="doc-images">
      ${docCard('الصورة الشخصية', s.personalPhotoUrl)}
      ${docCard('بطاقة الهوية (أمامي)', s.idFrontImageUrl)}
      ${docCard('صورة الترخيص المهني', s.practiceLicenseImageUrl)}
      ${docCard('صورة شهادة التخصص', s.specializationCertificateImageUrl)}
      ${docCard('صورة كارنيه النقابة', s.unionCardImageUrl)}
      ${docCard('بطاقة الهوية (خلفي)', s.idBackImageUrl)}
    </div>
  `;

  // Footer buttons
  if (s.status === 'Pending') {
    footer.innerHTML = `
      <button class="btn btn-success" onclick="approveSpecialist('${s.specialistId}'); closeModal();">قبول الطلب</button>
      <button class="btn btn-danger" onclick="closeModal(); openRejectModal('${s.specialistId}');">رفض الطلب</button>
      <button class="btn btn-outline" onclick="closeModal()">إغلاق</button>
    `;
  } else {
    footer.innerHTML = `
      <button class="btn btn-outline" onclick="closeModal()">إغلاق</button>
    `;
  }

  modal.classList.add('active');
}

function docCard(label, url) {
  return `
    <div class="doc-card">
      <div class="doc-card-label">${label}</div>
      ${
        url
          ? `<img src="${url}" alt="${label}" onclick="window.open('${url}', '_blank')" onerror="this.outerHTML='<div class=\\'doc-card-na\\'>غير متوفر</div>'">`
          : '<div class="doc-card-na">غير متوفر</div>'
      }
    </div>
  `;
}

function closeModal() {
  document.getElementById('detailModal').classList.remove('active');
}

// ─── Approve / Reject ─────────────────────────────────────

async function approveSpecialist(id) {
  await updateStatus(id, 2, null);
}

function openRejectModal(id) {
  selectedSpecialistId = id;
  document.getElementById('rejectionReason').value = '';
  document.getElementById('rejectModal').classList.add('active');
}

function closeRejectModal() {
  document.getElementById('rejectModal').classList.remove('active');
  selectedSpecialistId = null;
}

async function confirmReject() {
  const reason = document.getElementById('rejectionReason').value.trim();
  if (!reason) {
    showToast('الرجاء كتابة سبب الرفض.', 'error');
    return;
  }
  await updateStatus(selectedSpecialistId, 3, reason);
  closeRejectModal();
}

async function updateStatus(specialistId, status, rejectionReason) {
  try {
    const body = {
      specialistId,
      status,
    };
    if (rejectionReason) {
      body.rejectionReason = rejectionReason;
    }

    const res = await fetch(`${API_BASE}/Specialist/update-status`, {
      method: 'POST',
      headers: {
        accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await res.json();

    if (res.ok) {
      showToast(
        status === 2
          ? 'تم قبول المتخصص بنجاح ✅'
          : 'تم رفض المتخصص بنجاح ❌',
        'success'
      );
      fetchSpecialists(); // Refresh the list
    } else {
      showToast(data.message || 'حدث خطأ في تحديث الحالة.', 'error');
    }
  } catch (err) {
    console.error('Update status error:', err);
    showToast('فشل الاتصال بالسيرفر.', 'error');
  }
}

// ─── Toast ────────────────────────────────────────────────

function showToast(message, type = 'success') {
  const toast = document.getElementById('toast');
  toast.textContent = message;
  toast.className = `toast ${type} show`;

  setTimeout(() => {
    toast.classList.remove('show');
  }, 3500);
}

// ─── Close modals on overlay click ────────────────────────

document.getElementById('detailModal').addEventListener('click', (e) => {
  if (e.target === e.currentTarget) closeModal();
});

document.getElementById('rejectModal').addEventListener('click', (e) => {
  if (e.target === e.currentTarget) closeRejectModal();
});
