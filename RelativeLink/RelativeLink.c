#include <windows.h>

//
// RelativeLink.c
// by Jacob Appelbaum <jacob@appelbaum.net>
//
// Copyright 2008 Jacob Appelbaum <jacob@appelbaum.net>
// See LICENSE for licensing information
//
// This is a very small program to work around the lack of relative links 
// in any of the most recent builds of Windows.
//
// To build this, you need Cygwin or MSYS.
//
// You need to build the icon resource first:
// windres RelativeLink-res.rc RelativeLink-res.o
//
// Then you'll compile the program and include the icon object file:
// gcc -Wall -mwindows -o StartTorBrowserBundle RelativeLink.c RelativeLink-res.o
//
// End users will be able to use StartTorBrowserBundle.exe
// Put it in the proper place.
//

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    
    ZeroMemory ( &si, sizeof(si) );  
    si.cb = sizeof(si);
    ZeroMemory ( &pi, sizeof(pi) );

    TCHAR *ProgramToStart;
    ProgramToStart = TEXT ("App/vidalia.exe --datadir .\\Data\\Vidalia\\");

    if( !CreateProcess( 
        NULL, ProgramToStart, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi ))
    {
         MessageBox ( NULL, TEXT ("Unable to start Vidalia"), NULL, MB_OK);
         return -1;
    }

    return 0;
}
