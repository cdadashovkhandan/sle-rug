// import "/resources/min.js";
// import "/resources/delegate.js";
//! Computed questions
//! If-else hiding
//! On input events

// Integer

// String
$('#integer').on('change', function (event) {
    $('#formName').trigger('formUpdated');
})

// Boolean
$('#boolean').on('change', function (event) {
    $('#formName').trigger('formUpdated');
})

// Comp boolean
// = FlipBool(Boolean)
$('#formName').on('formUpdated', function (event) {
    $('#compBoolean')[0].checked = ! $('#boolean')[0].checked;
})

// Comp Integer
// = AddOne(Integer)
$('#formName').on('formUpdated', function (event) {
    $('#compInteger')[0].value = $('#integer')[0].valueAsNumber + 1;
})

//  "$('#<q.id>')[0].value"


// $('p:first-child a').on('click', function (event) {
//     event.preventDefault();
//     // do something else
//   });
