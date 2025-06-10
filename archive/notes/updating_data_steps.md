# Updating Data Fields Guide

When adding a new field to the MMA app data model, update these files in the following order:

## 1. Swift Model Structures
- `Models.swift`: Add the new property to relevant model structs (e.g., `FighterStats`, `APIFighter`)
  - Update model initializers
  - Add CodingKeys if necessary for JSON parsing

## 2. Core Data Model
- `MMADataModel.xcdatamodeld`: Add the new attribute to relevant Core Data entities (e.g., `CDFighter`)
  - Set appropriate data type and constraints

## 3. Core Data Manager
- `CoreDataManager.swift`: Update methods that save and fetch data
  - In `saveFighters()`: Add `setValue(newValue, forKey: "newFieldName")`
  - In `fetchAllFighters()`: Add the new field to struct initialization

## 4. Data Manager
- `DataManager.swift`: Update the `processNewData()` method to include the new field when creating model objects

## 5. Python Backend
- `app.py`: Update the `get_fighters()` function
  - Add null handling for the new column
  - Include the new field in the list of integer/string columns for type conversion

## 6. UI Components Using Hardcoded Data
- `FighterCard.swift`: Update preview data with the new field
- `FighterProfileView.swift`: Update preview data with the new field

## 7. CSV Data Source
- `fighter_info.csv`: Add a new column for the data

## Tips for Testing
1. After making changes, build the project to identify any compilation errors
2. Check for missing field errors in struct initializations
3. Verify data is correctly saved to and fetched from Core Data
4. Confirm the API correctly returns the new field
5. Validate UI components display the new data appropriately 