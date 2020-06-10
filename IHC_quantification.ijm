// clean up before we start, define important stuff
run("Close All");
run("Clear Results");
run("Set Measurements...", "mean area_fraction redirect=None decimal=2");
run("Summarize");
Composite = "Composite";

// Open Image
filename = File.openDialog('select file');
open(filename);
rename(Composite);
path = getDirectory("image");
name = File.nameWithoutExtension();

//	THIS DOES THE MAGIC :-)
processImage();
exit();

//Here you can find the called subfunctions, see below for details

function processImage(){
	preprocessing();
	thresholding();
	saving();
};	


function preprocessing(){//Prepare the picture for processing --> make RGB and a duplicate
	run("RGB Color");
	selectWindow("Composite");
	close();
	selectWindow("Composite (RGB)");
	
	//This is used to get rid of artefacts or non-tumor tissue in the histology picture
	//If your background is perfect, you can skip this step and comment it out with "//"
	//by painting the area black, it gets assigned the grey value 0. This will be converted to background in the next steps
	waitForUser("Background correction", "Artefacts in the background can screw up your thresholding. \nChoose the color picker and click on representative background. \nUse Flood fill tool and paint tool to get an even backround. \nYou can also remove tissue you want to exclude from evaluation. \nClick ok to proceed.");
	run("Duplicate...", "title=[Tumor_mask]");
	run("8-bit");

	//split the DAB image into color channels; close the not needed channels:
	//depending on your IHC staining, you need to choose the appropriate vector
	selectWindow("Composite (RGB)");
	run("Colour Deconvolution", "vectors=[H DAB] hide");
	close("Composite (RGB)-(Colour_3)");
	close("Composite (RGB)-(Colour_1)");
	
	//Prepare the channel for IHC marker quantification:
	selectWindow("Composite (RGB)-(Colour_2)");
	rename("CD44+ channel");
	run("Duplicate...", "title=[IHC_mask]");
	run("8-bit");
};

function thresholding(){
// for this function it is necessary to adjust the thresholding method according to your imaging data
	
	//calculate the area of the complete tumor
	selectWindow("Tumor_mask");
	setAutoThreshold("Triangle");
	run("Convert to Mask");
	remove_debris("Tumor_mask");
	run("Measure");
	
	selectWindow("IHC_mask");
	setAutoThreshold("Moments");
	run("Convert to Mask");
	remove_debris("IHC_mask");
	run("Measure");
	
	selectWindow("Tumor_mask");
	run("Create Selection");
	selectWindow("CD44+ channel");
	run("Restore Selection");
	//depending on how your selection turns out, remove this line
	run("Make Inverse");
	run("Measure");
};

function remove_debris(x){
	run("Duplicate...", "title=remove-debris");
	run("Make Binary");
	run("Fill Holes");
	run("Analyze Particles...", "size=0-1000 pixel show=Masks");
	run("Create Selection");
	selectWindow(x);
	run("Restore Selection");
	run("Set...", "value=0");
	run("Select None");
	selectWindow("Mask of remove-debris");
	close();
	selectWindow("remove-debris");
	close();
};

function saving(){
	//save the important images in a stack and the results in a .csv file
	run("Images to Stack", "name=" + name + "_evaluation title=[] use");
	savename = path + name + "_evaluation";
	saveAs(".Tiff", savename);
	saveresults = path + name + "_results.xls";
	saveAs("Results", saveresults);
	
	//exit the programm
	run("Close All");
	run("Clear Results");
	selectWindow("Results");
	run("Close");
};