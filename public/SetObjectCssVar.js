SetObjectCssVar(target,variable,color){
	function setFor(elem){
		var doc = elem.contentDocument;
		if(doc)
			doc.body.style[variable] = color;
	}
	if(typeof target == "string")
		querySelectorAll(target).forEach(setFor)
	else
		set(setFor)
}