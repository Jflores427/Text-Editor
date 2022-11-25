# Text-Editor

## Project Overview
Developed a Text Editor with x8086 Assembly Language to further test out my x86 Assembly Programming skills. At the time, I was studying several key topics in the language relating to Registers, Memory Addressing, Instructions, and Calling Conventions. As such, I engaged in the creation of this project to consolidate that knowledge and discover what areas of that knowledge required additional revision.

## Illustrations

### Photos of the Program

![image](https://user-images.githubusercontent.com/73263754/203962520-aa6c9bbb-cf03-4988-a60f-21d6f8be9d76.png)

***Figure 1: Initial home screen for the TXT.COM with a .txt file containing the content 'Hello There'***

![image](https://user-images.githubusercontent.com/73263754/204050131-cd6326fc-cc77-480e-b4c4-ba9e0985fa6f.png)

***Figure 2: Adding the phrase 'Wow!' to the text editor*** 


## Scope of Functionality
As addressed within the Project Overview, this project is a text editor that allows the user to edit any .txt file within the same directory/subdirectory as the TXT.COM file. Initially, the text editor begins in an insertion mode (F1) and the user can navigate the cursor with the left and right arrow keys. The user is granted the option to switch to an overtype mode by pressing (F2), which allows the user to overwrite characters where their cursor is currently situated. To save all the changes made to the document, the user needs to escape the program by pressing (ESC). 

As for its non-functionality, up and down arrow key scrolling, off-screen scrolling, and word wrap have not been implemented.
Moreover, the user is not able to copy and paste information within the text editor.

## Known Bugs
1) If the amount of .txt content exceeds the application page size, then we can expect the cursor to not start at the beginning of the file, with the file feeling
   cluttered and disorganized as a whole.
3) If you open the .txt file with a different text editor while the TXT.COM file is executing, then it doubles the output on the other text editor. 

## Prerequisities
A Working Knowledge of x8086 Assembly Language to understand the instructions presented in the .asm file.
A 32-bit x86 Emulator for running the program, I recommend DOSBox for this project.

## Installation (Relating to DOSBox)
1) Download/Install the latest version of DOSBox here: https://www.dosbox.com/download.php?main=1
2) Download the TXT.COM file onto your computer to a desired directory. E.g. Downloads Folder
3) Open the DOSBox application
4) Mount a Disk into the virtual environment from your local files to the folder containing the .EXE:
   On Windows, The command would be similar to 'MOUNT [desiredDiskName] [absolutePath]'
5) Change Disks by entering: '[desiredDiskName]:'
6) Run the .COM file with the 'TXT.COM' command followed by the name of the text file within the same directory. E.g. 'TXT.COM message.txt'
7) Write to your heart's content! (but don't go too crazy with it.)

## Technologies Used:
   1) Assembly (.asm) Code Editor (E.g. Notepad++)
   2) x8086 Assembly Language
   3) DOSBox application for compiling and linking the .asm and object files.
 
