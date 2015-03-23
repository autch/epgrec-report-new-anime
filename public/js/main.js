$(function() {
    var update_visibility = function(e) {
	    $('tr.prog-BS').toggle($('#hide-ch-type input[value="BS"]').prop("checked"));
	    $('tr.prog-CS').toggle($('#hide-ch-type input[value="CS"]').prop("checked"));
	    $('tr.prog-GR').toggle($('#hide-ch-type input[value="GR"]').prop("checked"));

	    if($('#hide-prog-status input[value="f"]').prop("checked")) {
	        $('tr.f').hide();
	    }
	    if($('#hide-prog-status input[value="r"]').prop("checked")) {
	        $('tr.r').hide();
	    }
	    if($('#hide-prog-status input[value="a"]').prop("checked")) {
	        $('tr.a').hide();
	    }
	    if($('#hide-prog-status input[value="nl"]').prop("checked")) {
	        $('tr.nl').hide();
	    } else {
	        $('tr.nl').not("tr.f").show();
        }
	    $('#count-shown').text($('table tbody tr:visible').length);
    };

    var initialize_toggle = function(index, elem) {
	    var $this = $(this);
	    if($this.prop("checked")) $this.parent("label").button("toggle");
    };

    $('#hide-ch-type input').each(initialize_toggle);
    $('#hide-prog-status input').each(initialize_toggle);

    update_visibility();

    $("#hide-prog-status").on("change", "input", update_visibility);
    $("#hide-ch-type").on("change", "input", update_visibility);

    $('button.add-ignore-keyword').on("click", function() {
	    $('#keyword').val($(this).attr("data-add-keyword")).select();
	    $('#keyword').select();
	    //	$('#add-keyword').modal("show");
    });


    $('#keyword').on("focus", function() {
    });

    $('#add-keyword form').on("submit", function() {
	    $.post($(this).attr("action"), {
	        keyword: $('#keyword').val(),
	    }, function(data, status, xhr) {
	        console.log($('#keyword').val());
	        $('#add-keyword').modal("hide");
	        location.reload(true);
	    });

	    return false;
    });
});

