window.addEventListener('DOMContentLoaded', () => {
  var el = document.getElementById('choices');
  var sortable = Sortable.create(el, {
    handle: '.sort-handle'
  });
});
