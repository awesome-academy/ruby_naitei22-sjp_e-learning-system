(function () {
  const form   = document.getElementById("filterForm");
  const select = document.getElementById("searchFieldSelect");
  const input  = document.getElementById("searchInput");

  function updateSearchName() {
    const v = (select && select.value) || "all";
    if (v === "content") {
      input.name = "q[content_cont]";
    } else if (v === "meaning") {
      input.name = "q[meaning_cont]";
    } else {
      input.name = "q[content_or_meaning_cont]";
    }
  }

  if (select && input) {
    select.addEventListener("change", updateSearchName);
    form.addEventListener("submit", updateSearchName);
    updateSearchName();
  }
})();
