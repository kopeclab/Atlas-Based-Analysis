/*
 * Usage: This plugin helps with cropping Bilateral Atlas Images perfectly in half based on the rectangle that 
 *  	  surrounds the bilateral Atlas. This helps to ensure that the left and right halves are symmetrical.
 * 
 * Instructions: Open a bilateral atlas image that needs to be cropped into a left and right hemisphere. 
 * 		  		 Use Plugins -> Macros -> Record and then draw a rectangle as perfectly around the boundaries of the atlas.
 * 		  		 The makeRectangle function for the rectangle you drew will show up on the Recorder. 
 * 		  		 Copy the 4 numbers between parenthesis which correspond to the x, y, xlength, and ylength of the rectangle.
 * 		  		 Input the 4 numbers and the Atlas Number and select the Left and Right Atlas directories.
 * 
 * Input: Input these x, y, xlength, and ylength of the rectangle into the first prompt and the number of the atlas.
 * 		  Select the results folder for the Left and then Right Atlas.
 * 		  
 * Output: Creates a left and right hemisphere saved into a specific folders.
 * 
 */




imageDirectory = getDirectory("image");
data = newArray(0);
var coordinates = "0,0,0,0";
var atlasNum = "00";

Dialog.create("Numbers for Analysis");
Dialog.addString("x, y, xlen, ylen", coordinates);
Dialog.addString("Atlas Number", atlasNum);
Dialog.show();
coordinates = Dialog.getString();
atlasNum = Dialog.getString();;

dirResultsLeft = getDirectory("Choose a Results folder for Left Atlas");
dirResultsRight = getDirectory("Select a Results folder for Right Atlas");

if (lengthOf(atlasNum) == 1) {
	atlasNum = "0" + atlasNum;
}

data = split(coordinates, ",");
for (i = 0; i < data.length;i++) {
	data[i] = parseInt(data[i]);
}
x = data[0];
y = data[1];
xlen = data[2];
ylen = data[3];
processFile(imageDirectory, dirResultsLeft, dirResultsRight, atlasNum, x, y, xlen, ylen);


//Functions
function processFile(dir, dirResultsLeft, dirResultsRight, num, x, y, xlen, ylen) {
    dimx = floor(xlen/2);
    dimy = ylen;
    leftx = x;
    lefty = y;
    rightx = x + dimx;
    righty = y;

    saveAs("Tiff", dir + num + "_left.tif");
    saveAs("Tiff", dir + num + "_right.tif");
    run("Close");

    open(dir + num + "_left.tif");
    makeRectangle(leftx, lefty, dimx, dimy);
    run("Crop");
    saveAs("Tiff", dirResultsLeft + num + "_left.tif");
    run("Close");

    open(dir + num + "_right.tif");
    makeRectangle(rightx, righty, dimx, dimy);
    run("Crop");
    saveAs("Tiff", dirResultsRight + num + "_right.tif");
    run("Close");
	
    a = File.delete(dir + num + "_left.tif");
    a = File.delete(dir + num + "_right.tif");
}

function append(arr, value) {
	arr2 = newArray(arr.length+1);
    for (i=0; i<arr.length; i++)
    	arr2[i] = arr[i];
    arr2[arr.length] = value;
    return arr2;
}


