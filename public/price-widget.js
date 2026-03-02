// Small renderer for the "Balkendiagramm Preis" Node-RED dashboard widget
// Supports two payload formats:
// 1) Node-RED createBarChart payload: [{ labels: [...], data: [[...],[...]], series: [...], avg: '...' }]
// 2) Array of { from: ISOString, price: number } (same contract as frontend PriceChart)

(function(window){
  const PV_COLOR_TODAY = '#FFA500';
  const PV_COLOR_TOMORROW = '#FF4136';
  const chartRegistry = {};

  // Read TACTICAL CSS values at runtime from DOM
  function getTacticalStyle() {
    const defaults = {
      textColor: '#c8e6f9',
      accentColor: '#00d4ff',
      fontFamily: '"Courier New", Courier, monospace',
      fontSize: 12
    };
    
    try {
      // Try to read from an existing md-card element
      const card = document.querySelector('md-card');
      if (!card) {
        console.log('[price-widget] No md-card found, using defaults');
        return defaults;
      }
      
      const computed = window.getComputedStyle(card);
      const style = {
        textColor: computed.color || defaults.textColor,
        accentColor: '#00d4ff', // TACTICAL CSS hardcoded accent
        fontFamily: computed.fontFamily || defaults.fontFamily,
        fontSize: parseInt(computed.fontSize) || defaults.fontSize
      };
      
      console.log('[price-widget] TACTICAL CSS values from DOM:', style);
      return style;
    } catch (e) {
      console.log('[price-widget] Error reading styles, using defaults:', e);
      return defaults;
    }
  }

  function parseCreateBarChart(payload){
    const p = Array.isArray(payload) ? payload[0] : payload;
    if (!p || !Array.isArray(p.labels) || !Array.isArray(p.data)) {
      return null;
    }
    const labels = p.labels;
    const datasets = p.data.map((arr, i) => ({
      label: (p.series && p.series[i]) || `series ${i}`,
      data: arr.map(v => v === null ? null : Number(v)),
      backgroundColor: i === 0 ? PV_COLOR_TODAY : PV_COLOR_TOMORROW
    }));
    return { labels, datasets, avg: p.avg };
  }

  function parseFromArray(payload){
    if (!Array.isArray(payload)) return null;
    const byDay = {};
    payload.forEach(d => {
      if (!d || !d.from) return;
      const dt = new Date(d.from);
      const day = dt.getFullYear() + '-' + String(dt.getMonth()+1).padStart(2,'0') + '-' + String(dt.getDate()).padStart(2,'0');
      const time = dt.getHours().toString().padStart(2,'0') + ':' + dt.getMinutes().toString().padStart(2,'0');
      byDay[day] = byDay[day] || {};
      byDay[day][time] = d.price;
    });
    const allTimes = Array.from(new Set(Object.values(byDay).flatMap(d => Object.keys(d)))).sort();
    const days = Object.keys(byDay).sort();
    const labels = allTimes;
    const todayArr = labels.map(t => byDay[days[0]] ? (byDay[days[0]][t] ?? null) : null);
    const tomorrowArr = days[1] ? labels.map(t => byDay[days[1]][t] ?? null) : null;
    const datasets = [
      { label: days[0] || 'Heute', data: todayArr, backgroundColor: PV_COLOR_TODAY },
    ];
    if (tomorrowArr) datasets.push({ label: days[1] || 'Morgen', data: tomorrowArr, backgroundColor: PV_COLOR_TOMORROW });
    return { labels, datasets };
  }

  function findNowIndex(labels){
    const now = new Date();
    const hours = now.getHours().toString().padStart(2,'0');
    const minutes = now.getMinutes();
    // Round down to nearest 15-minute interval
    const roundedMinutes = Math.floor(minutes / 15) * 15;
    const timeStr = hours + ':' + roundedMinutes.toString().padStart(2,'0');
    const idx = labels.indexOf(timeStr);
    return idx;
  }

  function ensureChartJs(){
    if (window.Chart) return Promise.resolve();
    return new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = 'https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js';
      s.onload = () => resolve();
      s.onerror = reject;
      document.head.appendChild(s);
    });
  }

  async function render(containerId, payload, opts={}){
    const container = document.getElementById(containerId);
    if (!container) return;
    let parsed = parseCreateBarChart(payload) || parseFromArray(payload);
    if (!parsed) {
      container.innerHTML = '<div style="color:#888">Keine Daten</div>';
      return;
    }

    await ensureChartJs().catch(()=>{});
    
    // Check global registry for existing chart
    let existing = chartRegistry[containerId];
    if (existing && existing instanceof Chart && !existing.destroyed) {
      console.log('[price-widget] Updating existing chart from registry');
      // Keep full labels in a separate property and set labels to full array
      existing._priceWidgetAllLabels = parsed.labels.slice();
      existing.data.labels = parsed.labels.slice();
      existing.data.datasets = parsed.datasets.map(ds => ({
        label: ds.label,
        data: ds.data.map(v => v === null ? NaN : v),
        backgroundColor: ds.backgroundColor,
        borderColor: ds.backgroundColor,
        borderWidth: 1
      }));
      // Update X-axis ticks callback for 4-hour labels (robust: accept numeric or string value)
      existing.options.scales.x.ticks.callback = function(value, index, ticks) {
        const full = (this && this.chart && this.chart.data && this.chart.data.labels) ? this.chart.data.labels : (existing._priceWidgetAllLabels || []);
        let i = -1;
        if (typeof value === 'number') i = value;
        else if (full) i = full.indexOf(value);
        if (i >= 0 && i % 8 === 0) return full[i];
        return '';
      };
      existing.update('none');
      drawNowLine(container, existing);
      return existing;
    }
    
    // Destroy old chart if exists
    if (existing && existing instanceof Chart) {
      existing.destroy();
    }
    
    // Get TACTICAL CSS styling
    const style = getTacticalStyle();
    
    // Create new chart
    let canvas = container.querySelector('canvas');
    if (!canvas) {
      container.innerHTML = '';
      canvas = document.createElement('canvas');
      canvas.style.width = '100%';
      canvas.style.height = '100%';
      canvas.style.display = 'block';
      container.appendChild(canvas);
    }

    const config = {
      type: 'bar',
      data: {
        // Use full labels array; ticks.callback will show every 4h
        labels: parsed.labels.slice(),
        datasets: parsed.datasets.map(ds => ({
          label: ds.label,
          data: ds.data.map(v => v === null ? NaN : v),
          backgroundColor: ds.backgroundColor,
          borderColor: ds.backgroundColor,
          borderWidth: 1
        }))
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: 'index', intersect: false },
        plugins: { 
          legend: { display: false }, 
          tooltip: { enabled: true }
        },
        scales: { 
          x: { 
            stacked: false,
            border: {
              display: true,
              color: '#00d7ff',
              width: 2
            },
            ticks: { 
              maxRotation: 90, 
              minRotation: 0,
              color: '#00d7ff',
              font: {
                size: 12,
                weight: 'bold',
                family: '"Courier New", Courier, monospace'
              },
              autoSkip: false,
              callback: function(value, index, ticks) {
                // Show label every 2 hours (8 × 15min intervals)
                const full = (this && this.chart && this.chart.data && this.chart.data.labels) ? this.chart.data.labels : (parsed.labels || []);
                let i = -1;
                if (typeof value === 'number') i = value;
                else if (full) i = full.indexOf(value);
                if (i >= 0 && i % 8 === 0) return full[i];
                return '';
              }
            },
            grid: {
              display: false // Manually drawn in animation.onComplete
            }
          }, 
          y: { 
            beginAtZero: true,
            border: {
              display: true,
              color: '#00d7ff',
              width: 2
            },
            ticks: {
              color: '#00d7ff',
              font: {
                size: 12,
                weight: 'bold',
                family: '"Courier New", Courier, monospace'
              }
            },
            grid: {
              display: false // Manually drawn in animation.onComplete
            }
          } 
        },
        animation: {
              onComplete: function(context) {
                const controller = this;
                const chart = controller.chart;
                const ctx = chart.ctx;

                const xScale = controller.scales ? (controller.scales['x-axis-0'] || controller.scales['x']) : null;
                const yScale = controller.scales ? (controller.scales['y-axis-0'] || controller.scales['y']) : null;
                if (!xScale || !yScale) return;

                ctx.save();

                // Draw Y-axis grid lines (horizontal)
                const yTicks = yScale.ticks || [];
                ctx.strokeStyle = 'rgba(0, 215, 255, 0.3)';
                ctx.lineWidth = 1;
                ctx.setLineDash([]);
                yTicks.forEach((tick, i) => {
                  const y = yScale.getPixelForTick(i);
                  ctx.beginPath();
                  ctx.moveTo(xScale.left, y);
                  ctx.lineTo(xScale.right, y);
                  ctx.stroke();
                });

                // Draw X-axis grid lines (vertical) - every 2 hours
                // Use full labels array (stored on chart) for indexing
                const labels = chart._priceWidgetAllLabels || (chart.config && chart.config.data && chart.config.data.labels) || [];
                labels.forEach((label, i) => {
                  if (i % 8 === 0) { // Every 8th line = 2 hours
                    const x = xScale.getPixelForTick(i);
                    ctx.beginPath();
                    ctx.moveTo(x, yScale.top);
                    ctx.lineTo(x, yScale.bottom);
                    ctx.stroke();
                  }
                });

                // Draw now-line using full labels
                const idx = findNowIndex(labels);
                if (idx >= 0) {
                  const x = xScale.getPixelForTick(idx);
                  ctx.strokeStyle = '#00FF00';
                  ctx.lineWidth = 3;
                  ctx.setLineDash([8, 4]);
                  ctx.beginPath();
                  ctx.moveTo(x, yScale.top);
                  ctx.lineTo(x, yScale.bottom);
                  ctx.stroke();
                }

                ctx.restore();
              }
            }
      }
    };

    const ctx = canvas.getContext('2d');
    const chart = new Chart(ctx, config);
    chart._priceWidgetCanvas = canvas; // Store canvas reference
    chartRegistry[containerId] = chart;
    
    return chart;
  }

  function drawNowLine(container, chart){
    // Trigger chart update to redraw plugin
    if (chart && !chart.destroyed) {
      chart.update('none');
    }
  }

  window.PriceWidget = window.PriceWidget || {};
  window.PriceWidget.render = render;
  window.PriceWidget.chartRegistry = chartRegistry;
  window.PriceWidget.updateNowLine = function(containerId) {
    const chart = chartRegistry[containerId];
    if (chart) drawNowLine(null, chart);
  };
})(window);
