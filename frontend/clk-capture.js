/**
 * GBO Ads — persist clk_id from ad funnel on your money site.
 * Deploy at site root; add before </head> on every page (or your app shell).
 * Kit version: see ../VERSION
 */
(function () {
  var params = new URLSearchParams(window.location.search);
  var id = params.get('clk_id');
  if (!id) return;
  try {
    localStorage.setItem('clk_id', id);
    sessionStorage.setItem('clk_id', id);
  } catch (e) {}
})();
