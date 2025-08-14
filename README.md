# Pauza_et_al-2025
## Outline

1. **MaxProject_split channels_multipleInputFolders.ijm** \
  - This `ImageJ` script allows for the selection of multiple input directories containing hyper stack (Z-series, multi channel) `.tif` images. These images are flattened (using the maximum intensity projection), split into single channel images, and saved as .tiff with an “`MAX_*_C?.tif`” extension to the selected output directory.
2. **DeconvolutionLab2_setScale_16bit_saveTiff_checksIftheFileAlreadyExists_waitForVaryingTime_inputFilesinthesameFolder_C1only_showProgressBar_c4.ijm** \
  - This `ImageJ` script processes images of a specified channel and feeds them for deconvolvolution using `DeconconvolutionLab2` - [https://bigwww.epfl.ch/deconvolution/deconvolutionlab2/](https://bigwww.epfl.ch/deconvolution/deconvolutionlab2/). 
  - Script uses Richardson-Lucy (RL) algorithm set for 25 iterations. This can be customised in Line 58.
- The code checks if deconvoluted image (`Final Display of RL`) has been generated every 10s. Once the image is found it is then set to 16-bit (from default output of 32-bit), set to match the scale of the original scale, and saved as .tiff with “`*_deconvolved.tif`” extension.
- Point Spread Function images required for `DeconvolutionLab2` can be generated using `PSF generator` - [https://bigwww.epfl.ch/algorithms/psfgenerator/](https://bigwww.epfl.ch/algorithms/psfgenerator/)

3. **Merge_4channels_intoComposite_differentInputDirectories_checkIfexists.ijm**
  - This `ImageJ` script takes four single channel images outputted from DeconvolutionLab2, looks for matching names (skips if the image name already exists in the output directory) and merges them into a single multi-channel image, and saved as .tiff with an “`*_combined.tif`” extension to the pre-selected output directory.
4. **Measure_area_CB_oneImageAtTime.ijm** 
- This `ImageJ` script semi-automates carotid body manual selection. 
- It first opens a composite image from the pre-selected input directory (one at the time).
- Auto-contrast selected channels (Lines 31-38) and `waitForUser;` to select the area corresponding to the carotid body (this can be done using the `polygon` or the `freehand` tool).
- Then it measures the area and save the selection using the "`_ROI_areaCB.roi`" extension.
- The script then goes on to measure the area of Tyrosine Hydroxylase (TH) positive signal (Channel 1) within the selected carotid body area. Selection is saved using "`_ROI_areaTH.roi`" extension.
- And opens a new image for manual carotid body area selection


### MaxProject_split channels_multipleInputFolders.ijm

```
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
); 
``` 

### DeconvolutionLab2_setScale_16bit_saveTiff_checksIftheFileAlreadyExists_waitForVaryingTime_inputFilesinthesameFolder_C1only_showProgressBar_c4.ijm
```
// Set input and output directories
inputDir = getDirectory("Choose the input folder");
outputDir = getDirectory("Choose the output folder");

// Ask user to specify the PSF file
psfPath = File.openDialog("Select the PSF file");

// List files in the folder
fileList = getFileList(inputDir);

// Filter files that match the '_C4.tif' pattern
matchingFiles = newArray();
for (i = 0; i < fileList.length; i++) {
    if (endsWith(fileList[i], "_C4.tif")) {
        matchingFiles = Array.concat(matchingFiles, fileList[i]);
    }
}

// Count total matching files
totalFiles = matchingFiles.length;

// Count how many files with '_deconvolved.tif' already exist in the output directory
alreadyDeconvolved = 0;
outputFiles = getFileList(outputDir);
for (i = 0; i < outputFiles.length; i++) {
    if (endsWith(outputFiles[i], "_deconvolved.tif")) {
        alreadyDeconvolved++;
    }
}


// Process remaining files
for (i = 0; i < matchingFiles.length; i++) {
    title = replace(matchingFiles[i], "_C4.tif", ""); // Remove '_C4.tif' to get the title
    outputFilePath = outputDir + title + "_C4_deconvolved.tif";

    // Skip if already deconvolved
    if (File.exists(outputFilePath)) {
        print("Skipping " + title + " - deconvolved file already exists.");
        continue;
    }

    // Calculate updated progress
    processedCount = i + 1 - alreadyDeconvolved;
    print("Processing file " + processedCount + " of " + (totalFiles - alreadyDeconvolved) + ": " + matchingFiles[i]);

    // Open the image
    filePath = inputDir + matchingFiles[i];
    open(filePath);

    // Get the original scale (distance in pixels)
    getPixelSize(unit, pixelWidth, pixelHeight);
    originalDistance = pixelWidth; // Assuming equal pixelWidth and pixelHeight for simplicity

    // Run DeconvolutionLab2 with RL 25 iterations and specified PSF
    image = " -image file " + filePath;
    psf = " -psf file " + psfPath; // Use the selected PSF path
    algorithm = " -algorithm RL 25";
    run("DeconvolutionLab2 Run", image + psf + algorithm);

    // Function to check if the specified window is open
    function isWindowOpen(windowTitle) {
        return isOpen(windowTitle);
    }

    // Define the window title
    windowTitle = "Final Display of RL";

    // Loop until the desired window is open
    while (!isWindowOpen(windowTitle)) {
        // Print a message indicating that the macro is waiting
        // print("Waiting for '" + windowTitle + "' to open...");
        print("Processing file " + processedCount + " of " + (totalFiles) + ": " + matchingFiles[i]);

        // Wait for 10 seconds (10,000 milliseconds)
        wait(10000);
    }

    // Select the deconvolved image window
    selectWindow("Final Display of RL");

    // Set the same scale as the original image (in pixels)
    run("Set Scale...", "distance=1 known=" + originalDistance + " pixel=1 unit=" + unit);

    // Convert to 16-bit
    run("16-bit");

    // Save the deconvolved image
    saveAs("Tiff", outputFilePath);

    // Close current image and result to prepare for the next file
    close("*");
}
```
### Merge_4channels_intoComposite_differentInputDirectories_checkIfexists.ijm

```
// Select input directories for each channel
inputDirC1 = getDirectory("Choose Input Folder for C1 Images");
inputDirC2 = getDirectory("Choose Input Folder for C2 Images");
inputDirC3 = getDirectory("Choose Input Folder for C3 Images");
inputDirC4 = getDirectory("Choose Input Folder for C4 Images");

// Select output directory
outputDir = getDirectory("Choose the Output Folder");

// Get list of files in the C1 input folder
fileListC1 = getFileList(inputDirC1);

// Loop through the files in the C1 folder
for (i = 0; i < fileListC1.length; i++) {
    // Only process files with "_C1_deconvolved.tif" extension
    if (endsWith(fileListC1[i], "_C1_deconvolved_scaled.tif")) {
        // Get the base name by removing the "_C1_deconvolved.tif" extension from the filename
        baseName = replace(fileListC1[i], "_C1_deconvolved_scaled.tif", "");

        // Check if the composite file already exists in the output directory
        compositePath = outputDir + baseName + "_composite.tif";
        if (File.exists(compositePath)) {
            print("Skipping: Composite file already exists for base name: " + baseName);
            continue;
        }

        // Construct full paths for each image (C1, C2, C3, C4)
        pathC1 = inputDirC1 + fileListC1[i];
        pathC2 = inputDirC2 + baseName + "_C2_deconvolved_scaled.tif";
        pathC3 = inputDirC3 + baseName + "_C3_deconvolved_scaled.tif";
        pathC4 = inputDirC4 + baseName + "_C4_deconvolved_scaled.tif";

        // Check if all the images (C1, C2, C3, C4) exist before proceeding
        if (File.exists(pathC1) && File.exists(pathC2) && File.exists(pathC3) && File.exists(pathC4)) {
            // Open all 4 images
            open(pathC1);
            open(pathC2);
            open(pathC3);
            open(pathC4);

            // Select the C2 image to get its scale
            selectWindow(baseName + "_C2_deconvolved_scaled.tif");
            getPixelSize(unit, pixelWidth, pixelHeight);

            // Select the C1 image and set the scale to match C2
            selectWindow(baseName + "_C1_deconvolved_scaled.tif");
            run("Set Scale...", "distance=1 known=" + pixelWidth + " pixel=1 unit=" + unit);

            // Convert C1 to 16-bit
            run("16-bit");

            // Merge the images as separate color channels in a composite image using window titles
            run("Merge Channels...", "c2=" + baseName + "_C1_deconvolved_scaled.tif c3=" + baseName + "_C2_deconvolved_scaled.tif c4=" + baseName + "_C3_deconvolved_scaled.tif c6=" + baseName + "_C4_deconvolved_scaled.tif create");

            // Rename the composite image
            rename(baseName + "_composite");

            // Save the composite image in the output folder
            saveAs("Tiff", compositePath);

            // Close all open images to prepare for the next iteration
            close("*");
        } else {
            // If any of the files are missing, print a warning
            print("Skipping: Missing channel image(s) for base name: " + baseName);
        }
    }
}
```

### Measure_area_CB_oneImageAtTime.ijm
```
// ImageJ Macro to measure area and positive signal in Channel 1 within selected ROI

run("Set Measurements...", "area redirect=None decimal=3");

// Prompt user to select input and output directories
inputDir = getDirectory("Choose input folder containing images");
outputDir = getDirectory("Choose output folder to save ROI");

// Get list of all files in the input directory
list = getFileList(inputDir);
totalFiles = list.length;

// Count already processed files
processedFiles = 0;

// Loop through each file in the input directory
for (i = 0; i < totalFiles; i++) {
    fileName = list[i];
    if (!endsWith(fileName, ".tif")) continue; // Skip non-TIF files

    baseName = replace(fileName, ".tif", "");
    
    // Check if output files already exist
    roiExists = File.exists(outputDir + baseName + "_ROI_areaCB.roi");
    THroiExists = File.exists(outputDir + baseName + "_ROI_areaTH.roi");
    if (roiExists && THroiExists) {
        print("Skipping " + fileName + " (already processed)");
        continue; // Skip if both output files already exist
    }

    // Open the image
    open(inputDir + fileName);
    imageName = getTitle();
    run("Enhance Contrast", "saturated=0.35");
	run("Next Slice [>]");
	run("Next Slice [>]");
	run("Enhance Contrast", "saturated=0.35");
    waitForUser;

    // Step 1: Measure the area of the selected ROI
    getStatistics(area);
    roiArea = area;

    // Save the ROI to the selected output folder
    roiName = baseName + "_ROI_areaCB.roi";
    roiFilePath = outputDir + roiName;
    run("ROI Manager...");
    roiManager("Add");
    roiManager("Save", roiFilePath); // Save the ROI as a zip file

    // Step 2: Process Channel 1
    run("Split Channels");
    selectWindow("C1-" + imageName);

    // Ensure the ROI is maintained in the active channel
    roiManager("Select", 0); // Select the saved ROI from the ROI Manager
    run("Make Inverse");
    run("Clear", "slice");
    run("Select None");

    // Threshold for positive signal in Channel 1
    setAutoThreshold("Default");
    run("Convert to Mask");
    run("Invert");
    selectWindow("C1-" + imageName);

    run("Analyze Particles...", "add");

    roiManager("Select", 0); // Select the initial ROI
    roiManager("Delete"); // Delete the initial ROI
    roiManager("Select All");
    run("Create Selection"); // Create a new ROI of the TH-positive area
    roiManager("Delete");
    roiManager("Add");
    roiManager("Select", 0); // Select the initial ROI

    // Save the ROI to the selected output folder
    THname = baseName + "_ROI_areaTH.roi";
    roiFilePathTH = outputDir + THname;
    roiManager("Save", roiFilePathTH); // Save the ROI as a zip file
    roiManager("Select All");
    roiManager("Delete"); // Delete the ROI

    // Measure the positive signal area within the selected ROI
    getStatistics(area);
    positiveArea = area; // Store the positive area measured within ROI

    // Deriving fraction
    fractionTH = (positiveArea * 100) / roiArea;

    // Step 3: Output the values in a single line in the summary table
    row = nResults; // Set current row index
    setResult("Image", row, imageName);
    setResult("ROI Area", row, roiArea);
    setResult("TH Area", row, positiveArea);
    setResult("%TH/CB Area", row, fractionTH);

    // Update progress
    processedFiles++;
    print("Processed " + processedFiles + "/" + totalFiles);

    // Step 4: Close all windows except the results
    run("Close All"); // Closes all image windows
    selectWindow("Results"); // Keep the Results window open
}

// Final progress report
print("Processing completed. Total files processed: " + processedFiles + "/" + totalFiles);

```

