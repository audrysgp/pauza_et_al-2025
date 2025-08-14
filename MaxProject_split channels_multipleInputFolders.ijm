// Select multiple input folders
n = getNumber("Enter number of input folders", 1);
inputDirs = newArray(n);
for (i = 0; i < n; i++) {
    inputDirs[i] = getDirectory("Choose input folder " + (i+1));
}

// Set output folder
outputDir = getDirectory("Choose the output folder");

// Loop through each selected input folder
for (i = 0; i < inputDirs.length; i++) {
    // List files in the current input folder
    fileList = getFileList(inputDirs[i]);

    // Loop through all files in the folder
    for (j = 0; j < fileList.length; j++) {
        // Open image using Bio-Formats Importer plugin
        filePath = inputDirs[i] + fileList[j];
        run("Bio-Formats Importer", "open=[" + filePath + "] autoscale");

        // Get the image title (file name without extension)
        title = getTitle();
        title = replace(title, ".tif", "");
		
		// Max project
		run("Z Project...", "projection=[Max Intensity]");

        // Split channels
        run("Split Channels");

      // Save each channel separately
    saveAs("Tiff", outputDir + "MAX_" + title + "_C4.tif");
    selectWindow("C1-MAX_" + title + ".tif");
    saveAs("Tiff", outputDir + "MAX_" + title + "_C1.tif");
    selectWindow("C2-MAX_" + title + ".tif");
    saveAs("Tiff", outputDir + "MAX_" + title + "_C2.tif");
    selectWindow("C3-MAX_" + title + ".tif");
    saveAs("Tiff", outputDir + "MAX_" + title + "_C3.tif");

        // Close all windows
        close("*");
    }
}
