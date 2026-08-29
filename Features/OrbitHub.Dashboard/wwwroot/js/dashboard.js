/**
 * OrbitHub — Dashboard Scripts
 * Feature: OrbitHub.Dashboard
 *
 * Client-side enhancements for the dashboard page.
 */

(function () {
    'use strict';

    // ── Auto-dismiss alerts after 8 seconds ──
    document.addEventListener('DOMContentLoaded', function () {
        const alerts = document.querySelectorAll('.dashboard-grid .alert');
        alerts.forEach(function (alert) {
            setTimeout(function () {
                alert.style.transition = 'opacity 0.3s';
                alert.style.opacity = '0';
                setTimeout(function () {
                    alert.remove();
                }, 300);
            }, 8000);
        });
    });

})();
