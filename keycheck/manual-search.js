// Search for the KeyCheck user manual. Everything happens in the page: it searches the
// section list in manual-search-index.js and nothing typed is sent anywhere.
(function () {
  "use strict";

  var MAX_RESULTS = 8;

  function words(text) {
    // "&" is kept inside words such as "M&E". Single letters would match almost everything,
    // but single digits are kept for searches like "gateway 3".
    return text.toLowerCase().split(/[^a-z0-9&]+/)
      .map(function (w) { return w.replace(/^&+|&+$/g, ""); })
      .filter(function (w) { return w.length > 1 || /\d/.test(w); });
  }

  function escapeHTML(text) {
    return text.replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }

  function escapeRegExp(text) {
    return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  // Every word typed must appear in the section. Matches in the heading count for more,
  // and words that start a word in the text count for more than ones found inside a word.
  function score(section, terms, phrase) {
    var heading = section.heading.toLowerCase();
    var text = section.text.toLowerCase();
    var total = 0;
    // The words typed, together and in order, count for most.
    if (terms.length > 1) {
      if (heading.indexOf(phrase) !== -1) total += 20;
      if (text.indexOf(phrase) !== -1) total += 8;
    }
    for (var i = 0; i < terms.length; i++) {
      var term = terms[i];
      var inHeading = heading.indexOf(term) !== -1;
      var inText = text.indexOf(term) !== -1;
      if (!inHeading && !inText) return 0;
      if (inHeading) total += 10;
      if (new RegExp("(^|[^a-z0-9])" + escapeRegExp(term)).test(text)) total += 3;
      else if (inText) total += 1;
    }
    return total;
  }

  // A short piece of text around the first match, with the matching words highlighted.
  function snippet(text, terms) {
    var lower = text.toLowerCase();
    var at = lower.indexOf(terms.join(" "));
    for (var i = 0; i < terms.length && at === -1; i++) at = lower.indexOf(terms[i]);
    var start = Math.max(0, at - 60);
    if (start > 0) start = text.indexOf(" ", start) + 1;
    var piece = text.slice(start, start + 170);
    if (start + 170 < text.length) piece = piece.replace(/\s+\S*$/, "") + "…";
    if (start > 0) piece = "…" + piece;
    // Split on the matches before escaping, so a word like "amp" can't match inside "&amp;".
    var pattern = new RegExp("(" + terms.map(escapeRegExp).join("|") + ")", "gi");
    return piece.split(pattern).map(function (part, i) {
      return i % 2 ? "<mark>" + escapeHTML(part) + "</mark>" : escapeHTML(part);
    }).join("");
  }

  function setUp(box) {
    var index = window.KEYCHECK_MANUAL_INDEX || [];
    // The box stays hidden if the scripts don't load, so it never shows without working.
    box.hidden = false;
    var input = box.querySelector("input");
    var status = box.querySelector(".manual-search-status");
    var list = box.querySelector(".manual-search-results");

    function show() {
      var query = input.value.trim();
      var terms = words(query);
      list.innerHTML = "";
      if (!terms.length) {
        status.textContent = "";
        box.classList.remove("has-results");
        return;
      }
      var found = index
        .map(function (section) { return { section: section, score: score(section, terms, terms.join(" ")) }; })
        .filter(function (r) { return r.score > 0; })
        .sort(function (a, b) { return b.score - a.score; });
      status.textContent = found.length
        ? (found.length === 1 ? "1 section found" : found.length + " sections found")
          + (found.length > MAX_RESULTS ? ", showing the best " + MAX_RESULTS : "")
        : "Nothing found for “" + query + "”. Try fewer or different words.";
      found.slice(0, MAX_RESULTS).forEach(function (r) {
        var item = document.createElement("li");
        var showChapter = r.section.heading !== r.section.chapter.replace(/^\d+\.\s*/, "");
        item.innerHTML =
          '<a href="' + escapeHTML(r.section.url) + '">' +
          '<span class="manual-search-place">' + escapeHTML(r.section.chapter.replace(/^(\d+)\.\s*/, "Chapter $1 · ")) + "</span>" +
          '<span class="manual-search-heading">' + escapeHTML(showChapter ? r.section.heading : "Introduction") + "</span>" +
          (r.section.text ? '<span class="manual-search-snippet">' + snippet(r.section.text, terms) + "</span>" : "") +
          "</a>";
        list.appendChild(item);
      });
      box.classList.toggle("has-results", found.length > 0);
    }

    input.addEventListener("input", show);
    input.addEventListener("keydown", function (event) {
      if (event.key === "Escape") {
        input.value = "";
        show();
      }
    });
    box.querySelector("form").addEventListener("submit", function (event) {
      event.preventDefault();
      var first = list.querySelector("a");
      if (first) location.href = first.href;
    });
    if (input.value) show();
  }

  function start() {
    var boxes = document.querySelectorAll("[data-manual-search]");
    for (var i = 0; i < boxes.length; i++) setUp(boxes[i]);
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
  else start();
})();
