/*
 * Usage: This plugin helps with creating new landmarks for the Atlas Landmarks Folder.
 * 
 * Instructions: Open the cropped Right Atlas that needs new landmarks. 
 * 				 Run this plugin. 
 * 				 Use BigWarp interface to create landmarks on the fixed image around places of interest.
 * 				 Export Landmarks into the Atlas Landmarks folder to save them for use in the Warp_Image plugin.
 * 
 * Input: Open a cropped Right Atlas that needs new landmarks.
 * 		  
 * Output: Opens BigWarp so the user can create Atlas Landmarks on a atlas with width and size of 10,000 which 
 *  	   is needed for the Warp_Image plugin.
 * 
 */


fullName = getTitle;
rescaled = fullName + "_rescaled";

run("Scale...", "x=- y=- width=10000 height=10000 interpolation=Bilinear average create title=[" + rescaled + "]");
run("Big Warp", "moving_image=" + rescaled + " target_image=" + rescaled);

