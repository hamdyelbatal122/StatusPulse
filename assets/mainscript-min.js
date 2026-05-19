/**
 * StatusPulse Dashboard Management Engine
 * Implements real-time stats extraction from SVGs, date navigation, and scope selector
 */

// Helper: Clean up date string format
function getFileName(dateStr) {
  return dateStr.replace(/[^0-9]/g, "");
}

// Update UI Title for Component selection
function updateTitle(compId) {
  const btn = document.getElementById("currcomp");
  const targetItem = document.getElementById(compId);
  if (btn && targetItem) {
    btn.title = compId;
    btn.innerHTML = targetItem.innerHTML;
  }
}

// Change the iframe location source
function setFrame(path) {
  const frame = document.getElementById("myFrame");
  if (frame) {
    frame.style.opacity = 0;
    setTimeout(() => {
      frame.src = path;
      frame.style.opacity = 1;
    }, 150);
  }
}

// Generate the frame path based on component and date
function choosefName(compId, dateFile) {
  if (compId === "gif" || compId === "ma") {
    return dateFile ? dateFile : "today.html";
  } else {
    return dateFile ? "instances/" + compId + "/" + dateFile : "instances/" + compId + "/index.html";
  }
}

// Main logic to determine which component file to view
function choosingComp() {
  const dateInput = document.getElementById("dt");
  const compButton = document.getElementById("currcomp");
  
  if (!dateInput || !compButton) return;
  
  const fordate = dateInput.value;
  const compId = compButton.title;
  const todayStr = new Date().toISOString().slice(0, 10);
  
  let filename = "";
  if (fordate === todayStr || fordate === "") {
    filename = choosefName(compId);
  } else {
    const formattedDateFile = getFileName(fordate) + ".html";
    filename = choosefName(compId, formattedDateFile);
  }
  
  setFrame(filename);
}

// Adaptively resize IFrame layout content
function resizeIframe(frame) {
  try {
    const doc = frame.contentDocument || frame.contentWindow.document;
    if (doc && doc.body) {
      const height = doc.body.scrollHeight;
      const width = doc.body.scrollWidth;
      frame.height = (height + 24) + "px";
      // Let standard responsive container handle width
    }
  } catch (e) {
    console.warn("Iframe resizing failed due to cross-origin restriction or loading delay.", e);
  }
}

// Compute metrics directly from the SVG inside the loaded IFrame
function calculateStats() {
  const frame = document.getElementById("myFrame");
  if (!frame) return;

  try {
    const doc = frame.contentDocument || frame.contentWindow.document;
    if (!doc) return;

    // Pull health status classes
    const passElements = doc.querySelectorAll('.pass, rect[fill="green"], rect[fill="#10b981"]');
    const failElements = doc.querySelectorAll('.fail, rect[fill="red"], rect[fill="#ef4444"]');
    const warnElements = doc.querySelectorAll('.warn, rect[fill="orange"], rect[fill="#f59e0b"]');
    const pendingElements = doc.querySelectorAll('.status, rect[fill="gray"], rect[fill="#1e293b"]');

    const healthy = passElements.length;
    const critical = failElements.length;
    const warning = warnElements.length;
    const pending = pendingElements.length;
    const total = healthy + critical + warning + pending;

    // Update parent document stats values
    document.getElementById("stat-healthy").innerText = healthy;
    document.getElementById("stat-critical").innerText = critical;
    document.getElementById("stat-total").innerText = total;

    // Compute uptime percentage
    const activeCheckedCount = healthy + critical + warning;
    let uptimeScore = 100;
    if (activeCheckedCount > 0) {
      uptimeScore = Math.round((healthy / activeCheckedCount) * 100);
    }
    document.getElementById("stat-uptime").innerText = uptimeScore + "%";

    // Dynamic System Health Badge update
    const systemStatusBadge = document.getElementById("system-status");
    if (systemStatusBadge) {
      systemStatusBadge.className = "status-badge";
      if (critical > 0) {
        systemStatusBadge.classList.add("critical");
        systemStatusBadge.innerHTML = '<span class="status-dot critical"></span>Critical Alert';
      } else if (warning > 0) {
        systemStatusBadge.classList.add("warning");
        systemStatusBadge.innerHTML = '<span class="status-dot warning"></span>Degraded State';
      } else if (healthy > 0) {
        systemStatusBadge.classList.add("healthy");
        systemStatusBadge.innerHTML = '<span class="status-dot healthy"></span>All Systems Nominal';
      } else {
        systemStatusBadge.classList.add("unknown");
        systemStatusBadge.innerHTML = '<span class="status-dot unknown"></span>No Metrics Reported';
      }
    }
  } catch (err) {
    console.log("Unable to compute dynamic statistics: ", err.message);
  }
}

// Bootstrap dashboard bindings
window.addEventListener("DOMContentLoaded", () => {
  const dateInput = document.getElementById("dt");
  if (dateInput) {
    const today = new Date();
    // Default timezone offset adjustment
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, "0");
    const day = String(today.getDate()).padStart(2, "0");
    dateInput.value = `${year}-${month}-${day}`;
  }

  // Bind calculation stats trigger on frame load
  const iframe = document.getElementById("myFrame");
  if (iframe) {
    iframe.addEventListener("load", () => {
      calculateStats();
      resizeIframe(iframe);
    });
  }

  // Periodic calculation retry for dynamic cron writing updates
  setInterval(() => {
    calculateStats();
  }, 10000);
});