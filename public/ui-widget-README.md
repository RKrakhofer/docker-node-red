Price Widget for Node-RED (embedded in this repo)

Installation / Usage

1. The `price-widget.js` is placed in `public/` and will be copied into the container image at `/data/public` during build.
2. Create a `ui_template` node in Node-RED and paste the content of `public/PRICE_WIDGET_UI_TEMPLATE.html` into it.
3. Connect the `ui_template` to the node that outputs the chart payload (e.g. the `createBarChart` function node).

Notes
- The widget loads Chart.js from CDN. If offline usage is required, host Chart.js locally.
- Colors: today = `#FFA500`, tomorrow = `#FF4136`.
