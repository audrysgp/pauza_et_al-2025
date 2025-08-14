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
    setBackgroundColor(0);
    run("Make Inverse");
    run("Clear", "slice");
    run("Select None");

    // Threshold for positive signal in Channel 1
    setAutoThreshold("Default dark");
    run("Convert to Mask");
   // run("Invert");
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
