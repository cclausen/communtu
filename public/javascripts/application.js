// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function searchResult(tab) {
	var tabs= new Array();
	tabs[0] = "bundles";
	tabs[1] = "livecds";
	tabs[2] = "packages";
	for (i=0; i<3; i++) {
		//alert("#"+tabs[i]);
		if (tabs[i] != tab) 
		$j("#" + tabs[i]).hide();
		
	}
	$j("#"+tab).show();
}

function user_profile_edit_show_category(id) {
    $$('div.category_active')[0].removeClassName('category_active') ;
    $('category_'+id).addClassName('category_active');

    var test = $$('div.bundle_category_active');
    var test2 = $$('div.bundle_category_active').size();
    var xxx=2;


    if (!$('category_bundle_'+id).hasClassName('bundle_category_active')) {
        if ($$('div.bundle_category_active').size() > 0) {
            $$('div.bundle_category_active')[0].hide();
            $$('div.bundle_category_active')[0].removeClassName('bundle_category_active') ;
        }
        $('category_bundle_'+id).addClassName('bundle_category_active');
        Effect.Appear('category_bundle_'+id, { duration: 0.3 });
    }
}

function user_profile_edit_save_categories() {
    new Ajax.Request(
        '/download/update_ratings', 
        {
            asynchronous:true, 
            evalScripts:false, 
            parameters:Form.serialize($('ajax'))
        });
}

function download_save_settings() {
    new Ajax.Request(
        '/download/update_data', 
        {
            asynchronous:true, 
            evalScripts:false, 
            parameters:Form.serialize($('ajax'))
        });
}

function toggle_visibility(id) {
       var e = document.getElementById(id);
       if(e.style.display == 'block')
          e.style.display = 'none';
       else
          e.style.display = 'block';
    }
