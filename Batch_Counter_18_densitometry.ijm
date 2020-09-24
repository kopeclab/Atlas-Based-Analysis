/*
 * INPUT:             1. Need to select a folder where Images are stored
 *                    2. Need to select folder for results to be stored                     
 *                    3. Image to be analyzed must be named with Atlas to analyze at the end of the name.
 *                    4. Requires there be a parent folder with Images to Analyze, Atlas Left,  Atlas Right, Atlas Analysis
 *                       
 * WHAT IT DOES: 	  This program will count the area and the number of cells in specified brain regions for every image in the folder.         
 *                    
 * OUTPUT:            1. It will create a new results folder where it will put a text document with a 
 *                       table with all the names of important brain regions and their specific cell count.
 * 					  2. It will also create an image with the specific atlas overlaid over the image.      
 * 					  3. It will also create summary statistics and a file with consolidated data
 */

operatingSystem = getInfo("os.name");
var fileSlash = "/";
if (indexOf(toLowerCase(operatingSystem), "windows") > -1) {
	fileSlash = "\\";
}

//Initializing Variables
var brainRegionsString = "";
var brainRegionsArray = newArray(0);
var totalBrainRegionCounts = "";
var totalBrainRegionSizes = "";
var leftSide = false;
var rightSide = false;
var minPixelSize = 20;
var maxPixelSize = 100;

//tells user about how to set up folders for analysis and what order to select folders to run
Dialog.create("Important");
Dialog.addMessage("Before Running:\nEnsure that the following folders are in the same directory as the Folder for Images.\n     - Atlas Right (All Right Atlases)\n     - Atlas Left (All Left Atlases)\n     - Atlas Analysis (Coordinates to Analyze)");
Dialog.addMessage("To Run:\n1. Select Folder where Images are Stored. (1st Step)\n2. Select Folder for Results (2nd Step)");
Dialog.addMessage("Output:\n1. For each Image, a Folder will be Created with:\n     - Text File with Counts from Important Brain Regions\n     - Original Image with Appropriate Atlas Overlaid on top.\n2. Summary Folder will be created with:\n     - Data from all Individual Analysis Compiled\n     - Summary Statistics for every Brain Region ");
Dialog.show();

//user can select which side of brain to analyze. Selecting both causes program to crash
Dialog.create("Side of Brain");
Dialog.addMessage("Hemisphere of Brain to Analyze:\nDo not select both.");
Dialog.addCheckbox("Left Side", false);
Dialog.addCheckbox("Right Side", false);
Dialog.addNumber("Minimum Pixel Size", minPixelSize);
Dialog.addNumber("Maximum Pixel Size", maxPixelSize);
Dialog.show();
leftSide = Dialog.getCheckbox();
rightSide = Dialog.getCheckbox();;
minPixelSize = Dialog.getNumber();;;
maxPixelSize = Dialog.getNumber();;;;


//asks for a folder of images and folder to save results in 
dirImages = getDirectory("Choose a Folder of Images");
dirResults = getDirectory("Select a Folder for Results");
setBatchMode(true);

//finds atlas analysis directory, and parent directory through text manipulations
upperDir = substring(dirImages, 0, lastIndexOf(substring(dirImages, 0, lengthOf(dirImages) - 1), fileSlash)+1);
atlasAnalysisDir = upperDir + "Atlas Analysis" + fileSlash;

//all brain regions are saved in a string and in array format 
brainRegionsString = File.openAsString(atlasAnalysisDir + "brain_regions.txt");
brainRegionsArray = split(brainRegionsString, ",  ");
brainRegionsArray[brainRegionsArray.length-1] = replace(brainRegionsArray[brainRegionsArray.length-1], "\n", ""); 

//sets up variables that will hold total counts and sizes for summary statistics
totalBrainRegionCounts = newArray(brainRegionsArray.length);
totalBrainRegionSizes = newArray(brainRegionsArray.length);

//Sets up Console to provide current information on analysis
print("Directory of Images:");
print(dirImages);
print("Directory of Results:");
print(dirResults);

//totalResultsFile will hold all the data from all of the atlases consolidated into one string
var totalResultsFile = "";

//calls process files which analyzes all images in directory and returns the names of images analyzed
names = processFiles(dirImages, dirResults);

//finds out name of folder holding all images to name summary after. 
imageSetName = substring(dirImages, lastIndexOf(substring(dirImages, 0, lengthOf(dirImages) - 1), fileSlash), lengthOf(dirImages)-1);
f = File.open(dirResults + "summary" + fileSlash + imageSetName + "_all_data.csv");
//prints consolidated counts into one summary file
print(f, totalResultsFile); 
File.close(f);

//opens file for summary counts for each brain region
f = File.open(dirResults + "summary" + fileSlash + imageSetName + "_summary.csv");
print(f, "Brain Region\tTotal Area\tTotal Integrated Density\t");
//calculates the average count per area 
for (i = 0; i < brainRegionsArray.length; i++) {
	average = 0;
	//prevents dividing by 0 when calculating average by checking to make sure that size is above 0
	if (totalBrainRegionSizes[i] > 0) {
		average = totalBrainRegionCounts[i] / totalBrainRegionSizes[i];
	} 
	
	//prints name of brain region, total Counts, total Size, and average across all atlases
	print(f, brainRegionsArray[i] + "\t" + totalBrainRegionSizes[i] + "\t" + totalBrainRegionCounts[i] + "\t" + average);
	
}
File.close(f);

//prints out to console all images that were analyzed
print("");
print("Successfully completed analyzing: ");
for (i=0; i<names.length; i++) {
   print(names[i]);
}

//FUNCTIONS

//CHANGE THIS CODE to modify console outputs during the program and to modify naming of output folders
//processFiles runs through every image in dirImages and calls processFile on them
function processFiles(dirImages, dirResults) {
	//finds list of images to analyze
	list = getFileList(dirImages);
	names = newArray(0);
	
	//sets up titles for consolidated results file and makes folder for summary data
	totalResultsFile += "Brain Region\t\tArea\tIntDen\n";
	File.makeDirectory(dirResults + "summary");

	//prints to console how many images to analyze and tells user that it has started
	print("");
	print("Total number of Images: " + list.length);
	print("");
	print("Processing Files");

	//loops through every image in the directory
	for (i=0; i<list.length; i++) {
		//CHANGE THIS CODE to modify how many image analyses are seen by the user. Currently, 2 images are seen analyzed by the user.
		//only allows user to see analysis on first 2 images. Afterward, batchmode is on and analysis is done in background
		if (i < 2) {
		 	setBatchMode(false);
		}

		//finds imagePath, name of image, and atlas number based on text manipulations
	    imagePath = "" + dirImages + list[i];
	    print(list[i]);
	    name = substring(list[i], 0, lengthOf(list[i]) - 4);
	    names = append(names, name);
	    atlasNum = findAtlasNum(name);
	    
	    //makes a folder for each image to store its counts data
	    File.makeDirectory(dirResults + name);
	    dirResult = dirResults + name + fileSlash;
	    
		//adds name of current atlas being analyzed for consolidated data file
	    totalResultsFile += "\n" + name + "\n";

	    //tells user which atlas is being used for atlas to confirm it is correct
	    print("Analyzing based on Atlas Number: " + atlasNum);

		//confirms that the atlas number being analyzed is valid and is above 0
	    actualNum = parseInt(atlasNum);
	    if (actualNum >= 0) {
	   	    processFile(imagePath, dirResult, atlasNum);
	        print("\\Update:Analysis based on Atlas Number: " + atlasNum + " - Completed");
	    }
	    else {
	        print("\\Update:Analysis based on Atlas Number: " + atlasNum + " - not successful");
	    }
	    setBatchMode(true);
   }

   return names;
}

//CHANGE THIS CODE to modify how each file is analyzed. This code currently thresholds by making binary, draws ROIs, measures area, and counts particles. 
//This function opens a single image, opens every ROI necessary based on the Atlas Number, and records the data into a text file.
function processFile(imagePath, dirResult, atlasNum) {
	//opens image for analysis
	open(imagePath);
	
	//data is an array that holds the final counts for each brain part for the section
	data = newArray(0);
	name = getTitle;
	w = getWidth;
	h = getHeight;

	//finds imageName and atlasNum from text manipulations
	imageName = substring(name, 0, lengthOf(name) - 4);

	//finds imagesDirectory, atlas analysis directory, and parent directory through text manipulations
	imagesDir = substring(imagePath, 0, lastIndexOf(substring(imagePath, 0, lengthOf(imagePath) - 1), fileSlash)+1);
	upperDir = substring(imagesDir, 0, lastIndexOf(substring(imagesDir, 0, lengthOf(imagesDir) - 1), fileSlash)+1);
	atlasAnalysisDir = upperDir + "Atlas Analysis" + fileSlash;

	//splits the correct file into array of lines for analysis
	lines = split(File.openAsString(atlasAnalysisDir + atlasNum + ".txt"), "\n");

	//CHANGE THIS CODE if you want to alter how the Atlas Analysis File is set up and read
	//First Line must be basewidth and baseheight for the original atlas image
	firstLine = split(lines[0], ",");
	baseWidth = firstLine[0];
	baseHeight = firstLine[1];
	ratiow = w/baseWidth;
	ratioh = h/baseHeight;
	//second line is the name of the parts that are to be analyzed for the specific slice
	secondLine = lines[1];
	partNames = split(secondLine, ", ");

	//CHANGE THIS CODE if you want to change how the thresholding is completed
	//basic thresholding to change into moments for further analysis
	selectWindow(name);
	//run("Make Binary");
	//run("Watershed");

	//CHANGE THIS CODE if you want to change what happens when each ROI is read
	//rest of the text file is the coordinates for the ROIs that are to be analyzed
	for (i = 2; i < lines.length; i ++) {
		roiCoordinates = split(lines[i], ",");

		//parses all of the coordinates into integers
		for (j = 0; j < roiCoordinates.length; j++) {
			roiCoordinates[j] = parseInt(roiCoordinates[j]);
		}

		//makes polygon and analyzes it. The data array is modified by the analyze_roi function to include data on the ROI drawn.
		selectWindow(name);
		makePolygonFromArray(roiCoordinates, ratiow, ratioh, w);		
		data = analyze_roi(data);
	}

	//opens txt file in Results directory for results
	f = File.open(dirResult + imageName + "_data.csv");
	
	print(f, "Brain Region\tArea\tIntDen");
	//prints the pertinent info into all result files
	for (i=0; i<partNames.length; i++) {
		print_line(f, partNames, data, i, atlasNum);
	}
	File.close(f);

	//closes the image to save RAM
	selectWindow(name);
	close();
	
	//assumes there is parent directory with 2 folders: 1 for images, 1 for atlas left and 1 for atlas right
	if (leftSide) {
		atlasPath = upperDir + "Atlas Left" + fileSlash + atlasNum + "_left.tif";
	}
	else if (rightSide) {
		atlasPath = upperDir + "Atlas Right"+ fileSlash + atlasNum + "_right.tif";
	}

	//CHANGE THIS CODE if you want to change the overlay or do not want it at all
	//rescales atlas image and overlays it over slide, then saves it in results folder
	overlay_image(imagesDir, name, imageName, atlasPath, dirResult, atlasNum);
}


//CHANGE THIS CODE to modify how an ROI is drawn for the left/right halves
//when given an array, ratiow, and ratioh, and totalWidth: draws a polygon around the specified brain part for analysis
function makePolygonFromArray(arr, ratiow, ratioh, totalWidth) {
	updatedX = newArray(0);
	updatedY = newArray(0);

	//CHANGE THIS CODE to modify how polygon is drawn based on array of coordiantes for a specific ROI from the correspinding AtlasAnalysis file
	//loops through x and y coodinates of the array and adjusts them with the ratio
	for (i = 0;i < arr.length; i++) {
		if (i%2 == 0) {
			if (rightSide) {
				updatedX = append(updatedX, arr[i] * ratiow);
			}
			else if (leftSide) {
				updatedX = append(updatedX, totalWidth - (arr[i] * ratiow));  //the original is for the right side so this calculates the left side x coordinate
			}
		}
		else if (i%2 == 1) {
			updatedY = append(updatedY, arr[i] * ratioh);
		}
	}
	//copies the last x and y coordinates for the remainder of the array so that a common length can be set
	lastx = updatedX[updatedX.length - 1];
	lasty = updatedY[updatedY.length - 1];
	for (i = updatedX.length; i < 250; i++) {
		updatedX = append(updatedX, lastx);
		updatedY = append(updatedY, lasty);
	}

    //draws polygon with constant length around the specified ROI
	makePolygon(updatedX[0], updatedY[0], updatedX[1], updatedY[1], updatedX[2], updatedY[2], updatedX[3], updatedY[3], updatedX[4], updatedY[4], updatedX[5], updatedY[5], updatedX[6], updatedY[6], updatedX[7], updatedY[7], updatedX[8], updatedY[8], updatedX[9], updatedY[9], updatedX[10], updatedY[10], updatedX[11], updatedY[11], updatedX[12], updatedY[12], updatedX[13], updatedY[13], updatedX[14], updatedY[14], updatedX[15], updatedY[15], updatedX[16], updatedY[16], updatedX[17], updatedY[17], updatedX[18], updatedY[18], updatedX[19], updatedY[19], updatedX[20], updatedY[20], updatedX[21], updatedY[21], updatedX[22], updatedY[22], updatedX[23], updatedY[23], updatedX[24], updatedY[24], updatedX[25], updatedY[25], updatedX[26], updatedY[26], updatedX[27], updatedY[27], updatedX[28], updatedY[28], updatedX[29], updatedY[29], updatedX[30], updatedY[30], updatedX[31], updatedY[31], updatedX[32], updatedY[32], updatedX[33], updatedY[33], updatedX[34], updatedY[34], updatedX[35], updatedY[35], updatedX[36], updatedY[36], updatedX[37], updatedY[37], updatedX[38], updatedY[38], updatedX[39], updatedY[39], updatedX[40], updatedY[40], updatedX[41], updatedY[41], updatedX[42], updatedY[42], updatedX[43], updatedY[43], updatedX[44], updatedY[44], updatedX[45], updatedY[45], updatedX[46], updatedY[46], updatedX[47], updatedY[47], updatedX[48], updatedY[48], updatedX[49], updatedY[49], updatedX[50], updatedY[50], updatedX[51], updatedY[51], updatedX[52], updatedY[52], updatedX[53], updatedY[53], updatedX[54], updatedY[54], updatedX[55], updatedY[55], updatedX[56], updatedY[56], updatedX[57], updatedY[57], updatedX[58], updatedY[58], updatedX[59], updatedY[59], updatedX[60], updatedY[60], updatedX[61], updatedY[61], updatedX[62], updatedY[62], updatedX[63], updatedY[63], updatedX[64], updatedY[64], updatedX[65], updatedY[65], updatedX[66], updatedY[66], updatedX[67], updatedY[67], updatedX[68], updatedY[68], updatedX[69], updatedY[69], updatedX[70], updatedY[70], updatedX[71], updatedY[71], updatedX[72], updatedY[72], updatedX[73], updatedY[73], updatedX[74], updatedY[74], updatedX[75], updatedY[75], updatedX[76], updatedY[76], updatedX[77], updatedY[77], updatedX[78], updatedY[78], updatedX[79], updatedY[79], updatedX[80], updatedY[80], updatedX[81], updatedY[81], updatedX[82], updatedY[82], updatedX[83], updatedY[83], updatedX[84], updatedY[84], updatedX[85], updatedY[85], updatedX[86], updatedY[86], updatedX[87], updatedY[87], updatedX[88], updatedY[88], updatedX[89], updatedY[89], updatedX[90], updatedY[90], updatedX[91], updatedY[91], updatedX[92], updatedY[92], updatedX[93], updatedY[93], updatedX[94], updatedY[94], updatedX[95], updatedY[95], updatedX[96], updatedY[96], updatedX[97], updatedY[97], updatedX[98], updatedY[98], updatedX[99], updatedY[99], updatedX[100], updatedY[100], updatedX[101], updatedY[101], updatedX[102], updatedY[102], updatedX[103], updatedY[103], updatedX[104], updatedY[104], updatedX[105], updatedY[105], updatedX[106], updatedY[106], updatedX[107], updatedY[107], updatedX[108], updatedY[108], updatedX[109], updatedY[109], updatedX[110], updatedY[110], updatedX[111], updatedY[111], updatedX[112], updatedY[112], updatedX[113], updatedY[113], updatedX[114], updatedY[114], updatedX[115], updatedY[115], updatedX[116], updatedY[116], updatedX[117], updatedY[117], updatedX[118], updatedY[118], updatedX[119], updatedY[119], updatedX[120], updatedY[120], updatedX[121], updatedY[121], updatedX[122], updatedY[122], updatedX[123], updatedY[123], updatedX[124], updatedY[124], updatedX[125], updatedY[125], updatedX[126], updatedY[126], updatedX[127], updatedY[127], updatedX[128], updatedY[128], updatedX[129], updatedY[129], updatedX[130], updatedY[130], updatedX[131], updatedY[131], updatedX[132], updatedY[132], updatedX[133], updatedY[133], updatedX[134], updatedY[134], updatedX[135], updatedY[135], updatedX[136], updatedY[136], updatedX[137], updatedY[137], updatedX[138], updatedY[138], updatedX[139], updatedY[139], updatedX[140], updatedY[140], updatedX[141], updatedY[141], updatedX[142], updatedY[142], updatedX[143], updatedY[143], updatedX[144], updatedY[144], updatedX[145], updatedY[145], updatedX[146], updatedY[146], updatedX[147], updatedY[147], updatedX[148], updatedY[148], updatedX[149], updatedY[149], updatedX[150], updatedY[150], updatedX[151], updatedY[151], updatedX[152], updatedY[152], updatedX[153], updatedY[153], updatedX[154], updatedY[154], updatedX[155], updatedY[155], updatedX[156], updatedY[156], updatedX[157], updatedY[157], updatedX[158], updatedY[158], updatedX[159], updatedY[159], updatedX[160], updatedY[160], updatedX[161], updatedY[161], updatedX[162], updatedY[162], updatedX[163], updatedY[163], updatedX[164], updatedY[164], updatedX[165], updatedY[165], updatedX[166], updatedY[166], updatedX[167], updatedY[167], updatedX[168], updatedY[168], updatedX[169], updatedY[169], updatedX[170], updatedY[170], updatedX[171], updatedY[171], updatedX[172], updatedY[172], updatedX[173], updatedY[173], updatedX[174], updatedY[174], updatedX[175], updatedY[175], updatedX[176], updatedY[176], updatedX[177], updatedY[177], updatedX[178], updatedY[178], updatedX[179], updatedY[179], updatedX[180], updatedY[180], updatedX[181], updatedY[181], updatedX[182], updatedY[182], updatedX[183], updatedY[183], updatedX[184], updatedY[184], updatedX[185], updatedY[185], updatedX[186], updatedY[186], updatedX[187], updatedY[187], updatedX[188], updatedY[188], updatedX[189], updatedY[189], updatedX[190], updatedY[190], updatedX[191], updatedY[191], updatedX[192], updatedY[192], updatedX[193], updatedY[193], updatedX[194], updatedY[194], updatedX[195], updatedY[195], updatedX[196], updatedY[196], updatedX[197], updatedY[197], updatedX[198], updatedY[198], updatedX[199], updatedY[199], updatedX[200], updatedY[200], updatedX[201], updatedY[201], updatedX[202], updatedY[202], updatedX[203], updatedY[203], updatedX[204], updatedY[204], updatedX[205], updatedY[205], updatedX[206], updatedY[206], updatedX[207], updatedY[207], updatedX[208], updatedY[208], updatedX[209], updatedY[209], updatedX[210], updatedY[210], updatedX[211], updatedY[211], updatedX[212], updatedY[212], updatedX[213], updatedY[213], updatedX[214], updatedY[214], updatedX[215], updatedY[215], updatedX[216], updatedY[216], updatedX[217], updatedY[217], updatedX[218], updatedY[218], updatedX[219], updatedY[219], updatedX[220], updatedY[220], updatedX[221], updatedY[221], updatedX[222], updatedY[222], updatedX[223], updatedY[223], updatedX[224], updatedY[224], updatedX[225], updatedY[225], updatedX[226], updatedY[226], updatedX[227], updatedY[227], updatedX[228], updatedY[228], updatedX[229], updatedY[229], updatedX[230], updatedY[230], updatedX[231], updatedY[231], updatedX[232], updatedY[232], updatedX[233], updatedY[233], updatedX[234], updatedY[234], updatedX[235], updatedY[235], updatedX[236], updatedY[236], updatedX[237], updatedY[237], updatedX[238], updatedY[238], updatedX[239], updatedY[239], updatedX[240], updatedY[240], updatedX[241], updatedY[241], updatedX[242], updatedY[242], updatedX[243], updatedY[243], updatedX[244], updatedY[244], updatedX[245], updatedY[245], updatedX[246], updatedY[246], updatedX[247], updatedY[247], updatedX[248], updatedY[248], updatedX[249], updatedY[249]); 
}


//CHANGE THIS FUNCTION to alter what is quantified after drawing a specific ROI
//To alter funciton, record a macro to be completed after an ROI has been drawn.
//Paste the new macro here and assign values to be recorded to variables that are appended to dataArray.
//Update print_line() which currently works for two data points for each ROI
//Measures size and counts particles inside a drawn ROI
function analyze_roi(dataArray) {
	//measures the Area of the ROI
    run("Set Scale...", "distance=300 known=1 pixel=1 unit=inch");
    run("Measure");
    size = getResult("Area", 0);
    intden = getResult("IntDen", 0);
    close("Results");
/*
    //counts number of particles based on maximum and minimum sizes specified by user
    run("Analyze Particles...", "size=" + minPixelSize + "-" + maxPixelSize + " pixel display exclude clear include add in_situ");
	//checks if there is a results folder which only wont open if there are zero valid particles
    hasResults = false;
    allWindowsList = getList("window.titles");
    for (i = 0; i < allWindowsList.length; i++) {
       if (allWindowsList[i] == "Results") {
          hasResults = true;
       }
    }
	//counts number of valid cells
    if (hasResults == true) {
       selectWindow("Results");
       numberParticles = nResults;
       close("Results");
    } else if (hasResults == false) {
       numberParticles = 0;
    } 
 */

	//CHANGE THIS CODE to add or modify the variables added to data array for the specific ROI that has been drawn.
    //adds size and counts to array for output
    dataArray = append(dataArray, size);
    dataArray = append(dataArray, intden);
    return dataArray;
}

//CHANGE THIS CODE if there are any updates to data stored in dataArray. Currently, the value in dataArray at i*2 and i*2 + 1 correspond to the partname at i.
//prints a line in the ouput file if given the file, array of cell count, name of the brain part, index of brain part
function print_line(f, partNames, dataArray, i, atlasNum) {
	//calculates count per area by dividing count by area
	countPerArea = 0;
	/*if (parseFloat(dataArray[i*2]) > 0) {
		countPerArea = parseFloat(dataArray[i*2+1]) / parseFloat(dataArray[i*2]);
	}*/
 
    //adds result to the consolidated data file
    newLine = partNames[i] + "\t" + atlasNum + "\t" + dataArray[i*2] + "\t" + dataArray[i*2+1];
	totalResultsFile += newLine + "\n";

	//adding the data to the totals for specific brain region
	for (j = 0; j < brainRegionsArray.length; j++) {
		if (toLowerCase(partNames[i]) == toLowerCase(brainRegionsArray[j])) {
			totalBrainRegionCounts[j] += parseFloat(dataArray[i*2+1]);
			totalBrainRegionSizes[j] += parseFloat(dataArray[i*2]);
		}
	}

	//prints into current image result spreadsheet
    print(f, partNames[i] + "\t" + dataArray[i*2] + "\t" + dataArray[i*2+1]);
}

//CHANGE THIS COIDE if you want to change the opacity of the overlay or do not want this functionality
//rescales atlas image and overlays it over slide, then saves it in results folder
function overlay_image(path, name, imageName, atlasPath, dirResults, atlasNum) {
	//opens the image and the correct atlas
    open(path + name);
    open(atlasPath);
    run("Scale...", "x=- y=- width=" + w + " height=" + h + " interpolation=Bilinear average create title=scaled.tif");
    selectWindow(name);
    //CHANGE THIS CODE to modify the opacity of the atlas image.
    run("Add Image...", "image=scaled.tif x=0 y=0 opacity=20");
    run("Flatten");

	//CHANGE THIS CODE to modify the file format of the overlaid image.
	//saves image based on left/right side
    if (leftSide) {
        saveAs("Jpeg",  dirResults + imageName + "_overlay.jpg");
        close();

        selectWindow(atlasNum + "_left.tif");
        close();
    }
    if (rightSide) {
        saveAs("Jpeg",  dirResults + imageName + "_overlay.jpg");
        close();
       
        selectWindow(atlasNum + "_right.tif");
        close();
    }

	//closes image to save RAM
   	selectWindow(name);
   	close();
  	selectWindow("scaled.tif");
   	close();
}


//for adding values to an array
function append(arr, value) {
      arr2 = newArray(arr.length+1);
      for (i=0; i<arr.length; i++)
          arr2[i] = arr[i];
      arr2[arr.length] = value;
      return arr2;
}

//deletes last value of an array
function deleteLastValue(arr) {
      arr2 = newArray(arr.length - 1);
      for (i=0; i< (arr.length - 1); i++)
           arr2[i] = arr[i];
      return arr2;
}

//determines atlas number by finding the last digits of the name. It continues looking for digits until it finds the first non-digit.
function findAtlasNum(name) {
	atlasNum = "";
	for (i = lengthOf(name);i > 0;i--) {
		letter = substring(name, i-1, i);
		if (isNaN(parseInt(letter)))  {
			break;
		}
		atlasNum = letter + atlasNum;
	}
	return atlasNum;
}

