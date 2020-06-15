/* This program takes an open image named with "left" or "right" and an atlas number at the end of the name, 
 * creates a set of landmarks based on the atlas number, and then opens up big warp for the user. Once 
 * big warp is open, the user must change the landmarks based on their judgement. 
 * Once completed, the user must select file -> export imageplus and then save the image.
 * 
 * What is needed: A correctly named image that is open in FIJI. It must have either left or right in the name.
 * The image must also be in a folder that is in a parent directory that contains all the left/right atlases 
 * as well as a folder for Atlas Landmarks and a folder for File Landmarks.
 * 
 * What it does: It creates a custom landmark file for the current image and saves it in the File Landmarks folder based on the ratio of the sizes.
 * It also opens bigwarp for the user.
 * 
 * Output: Bigwarp is open so the user must import the correct landmarks from the File Landmarks folder.
 * 
 */

operatingSystem = getInfo("os.name");
var fileSlash = "/";
if (indexOf(toLowerCase(operatingSystem), "windows") > -1) {
	fileSlash = "\\";
}

//gets information on the current open image
run("Properties...", "channels=1 slices=1 frames=1 unit=pixel pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000 origin=1,1,1");
setBatchMode(true);

fullName = getTitle;
width = getWidth;
height = getHeight;
imageDirectory = getDirectory("image");
print("Warping: " + fullName);

//determines atlasNumber
name = substring(fullName, 0, indexOf(fullName, "."));
atlasNum = findAtlasNum(name);

//determines left or right atlas
left = false;
right = false;
if ((indexOf(toLowerCase(name), "left")) >= 0 ) {
	left = true;		
}
else {
	right = true;
}

//determines file path of corresponding atlas
parentDirectory = substring(imageDirectory, 0, lastIndexOf(substring(imageDirectory, 0, lengthOf(imageDirectory) - 1), fileSlash) + 1);
if (left) {
	atlasName = atlasNum + "_left.tif";
	atlasDirectory = parentDirectory + "Atlas Left" + fileSlash + atlasName;
}
else {
	atlasName = atlasNum + "_right.tif";
	atlasDirectory = parentDirectory + "Atlas Right" + fileSlash + atlasName;
}

//rescales the atlas image correctly
open(atlasDirectory);
run("Scale...", "x=- y=- width=" + toString(width) + " height=" + toString(height) + " interpolation=Bilinear average create title=" + atlasNum + "_scaled.tif");
selectWindow(atlasName);
close();

//determines correct ratios to multiply each width and height
ratiow = width/10000;
ratioh = height/10000;

landmarkDirectory = parentDirectory + "Atlas Landmarks" + fileSlash;

//reads in base landmark file and updates it based on current image dimensions
lines = split(File.openAsString(landmarkDirectory + atlasNum + ".csv"), "\n");
f = File.open(parentDirectory + "File Landmarks" + fileSlash + name + "_landmarks.txt");
for (i = 0;i < lines.length;i ++) {
	values = split(lines[i], ",");
	finalString = "";
	if (right) {
		values[4] = "\"" + toString(parseInt(replace(values[4], "\"", "")) * ratiow) + "\""; 
	}
	else {
		values[4] = "\"" + toString(width - (parseInt(replace(values[4], "\"", "")) * ratiow)) + "\"";
	}
	values[5] = "\"" + toString(parseInt(replace(values[5], "\"", "")) * ratioh) + "\""; 
	values[2] = values[4];
	values[3] = values[5];
	values[1] = "true";
	for (j = 0; j < values.length - 1; j++) {
		finalString += values[j] + ",";
	}
	finalString += values[values.length - 1];
	print(f, finalString);
}

//converts the txt file into a csv file to be used by bigwarp
renamed = File.rename(parentDirectory + "File Landmarks" + fileSlash + name + "_landmarks.txt", parentDirectory + "File Landmarks" + fileSlash + name + "_landmarks.csv");

//runs bigwarp for user to change manually
selectWindow(atlasNum + "_scaled.tif");
run("Big Warp", "moving_image=" + fullName + " target_image=" + atlasNum + "_scaled.tif");
selectWindow(atlasNum + "_scaled.tif");
close();


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
