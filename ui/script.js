// Elements
const els = {
  root: document.getElementById('bus-dashboard'),
  lineName: document.getElementById('line-name'),
  lineNumber: document.getElementById('line-number'),
  currentStation: document.getElementById('current-station'),
  nextStation: document.getElementById('next-station'),
  distance: document.getElementById('distance'),
  passengers: document.getElementById('passengers'),
  passengerFill: document.getElementById('passenger-fill'),
  earningsRow: document.getElementById('earnings-row'),
  earnings: document.getElementById('earnings'),
};

// Accent color
function setAccentColor(color) {
  const r = (color && color.r) ?? 30;
  const g = (color && color.g) ?? 144;
  const b = (color && color.b) ?? 255;
  document.documentElement.style.setProperty('--accent', `${r}, ${g}, ${b}`);
}

// UI update from game messages
function updateUI(data) {
  if (!data) return;
  els.lineName.textContent = data.lineName ?? 'Line';
  els.lineNumber.textContent = data.lineNumber ?? '-';
  const totalStations = data.totalStations ?? 0;
  els.currentStation.textContent = `${data.currentStationIndex ?? 0}/${totalStations}`;
  els.nextStation.textContent = `${data.nextStationIndex ?? 0}/${totalStations}`;
  els.distance.textContent = `${data.distanceToNext ?? 0} m`;

  const maxPassengers = data.maxPassengers ?? 0;
  const currentPassengers = data.currentPassengers ?? 0;
  els.passengers.textContent = `${currentPassengers}/${maxPassengers}`;
  const occ = maxPassengers > 0 ? Math.min(currentPassengers / maxPassengers, 1) : 0;
  els.passengerFill.style.width = `${Math.round(occ * 100)}%`;

  setAccentColor(data.color);

  if (data.showEarnings && typeof data.totalEarnings === 'number') {
    els.earningsRow.style.display = '';
    els.earnings.textContent = `$${data.totalEarnings}`;
  } else {
    els.earningsRow.style.display = 'none';
  }
}

// Visibility toggle
function setVisible(visible) {
  els.root.classList.toggle('hidden', !visible);
}

// Messages from game (NUI)
window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.type) return;
  switch (data.type) {
    case 'bus_dashboard_update':
      updateUI(data);
      break;
    case 'bus_dashboard_visible':
      setVisible(!!data.visible);
      break;
  }
});