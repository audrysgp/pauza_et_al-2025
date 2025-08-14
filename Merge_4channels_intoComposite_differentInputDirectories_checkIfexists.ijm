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
