@echo off
setlocal EnableDelayedExpansion

:: Check if a folder path is provided as an argument
if "%~1"=="" (
  echo Usage: %~0 ^<folder_path^>
  exit /b 1
)

:: The input folder path
set "main_folder=%~1"
echo Main folder: %main_folder%

:: Check if the provided path is a valid directory
if not exist "%main_folder%\*" (
  echo Error: '%main_folder%' is not a valid directory.
  exit /b 1
)

:: Loop through all subfolders in the main folder
for /d %%S in ("%main_folder%\*") do (
  :: Ensure it's a directory
  if exist "%%S\" (
    :: Extract FirstName LastName from the subfolder name
    set "folder_name=%%~nxS"
    
    :: Split the folder name by " - " to isolate FirstName LastName
    for /f "tokens=3 delims=-" %%A in ("!folder_name!") do (
      for /f "tokens=1,2 delims= " %%B in ("%%A") do (
        set "first_name=%%B"
        set "last_name=%%C"
        set "first_name_last_name=!first_name!_!last_name!"
      )
    )

    echo Processing subfolder: %%~nxS as !first_name_last_name!

    :: Loop through all files in the subfolder
    for %%F in ("%%S\*") do (
      if exist "%%F" (
        :: Get the filename
        set "filename=%%~nxF"

        :: Create the new filename by prepending FirstName_LastName
        set "new_filename=!first_name_last_name!_%%~nxF"

        :: Move and rename the file to the main folder
        move /y "%%F" "%main_folder%\!new_filename!"
        echo Moved: %%F -> %main_folder%\!new_filename!
      )
    )

    :: Attempt to delete the subfolder (will only work if it's empty)
    rd "%%S" 2>nul
    if not exist "%%S\" echo Deleted subfolder: %%S
  )
)

:: Delete index.html in the main folder if it exists
if exist "%main_folder%\index.html" (
  del "%main_folder%\index.html"
  echo Deleted: %main_folder%\index.html
)

echo Rename and move completed.
