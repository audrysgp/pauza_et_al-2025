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
