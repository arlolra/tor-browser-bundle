#include <windows.h>
#include <stdio.h>
#include <tchar.h>

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

// Get the absolute path to a subdirectory of the current directory; i.e.
// "C:\cwd\reldir". Returns a malloc-allocated string or NULL on error.
LPTSTR GetSubdirectory(LPCTSTR reldir)
{
    DWORD bufsize, n;
    int len;
    LPTSTR cwd, subdir;

    cwd = NULL;
    subdir = NULL;

    // The first call to GetCurrentDirectory gets the buffer size; the second
    // fills the buffer.
    bufsize = GetCurrentDirectory(0, NULL);
    if (bufsize == 0)
        goto bail;
    cwd = (LPTSTR) malloc(bufsize * sizeof(TCHAR));
    if (cwd == NULL)
        goto bail;
    n = GetCurrentDirectory(bufsize, cwd);
    if (n == 0 || n >= bufsize)
        goto bail;

    bufsize = _tcslen(cwd) + 1 + _tcslen(reldir) + 1;
    subdir = (LPTSTR) malloc(bufsize * sizeof(TCHAR));
    if (subdir == NULL)
        goto bail;
    len = _sntprintf(subdir, bufsize, "%s\\%s", cwd, reldir);
    if (len < 0 || (DWORD) len >= bufsize)
        goto bail;

    free(cwd);
    return subdir;

bail:
    if (cwd != NULL)
        free(cwd);
    if (subdir != NULL)
        free(subdir);
    return NULL;
}

// Add a directory to the beginning of the PATH environment variable. Returns 0
// on failure, nonzero on success.
// http://msdn.microsoft.com/en-us/library/windows/desktop/ms682009%28v=vs.85%29.aspx
DWORD PrependToPath(LPCTSTR dir)
{
    DWORD bufsize, n, rc, err;
    int len;
    LPTSTR path, value;

    path = NULL;
    value = NULL;

    // First find out how big a buffer we need.
    bufsize = GetEnvironmentVariable(TEXT ("PATH"), NULL, 0);
    if (bufsize == 0)
    {
        err = GetLastError();
        if (err == ERROR_ENVVAR_NOT_FOUND)
            // If the variable doesn't yet exist, just set it and return.
            return SetEnvironmentVariable(TEXT ("PATH"), dir);
        else
            goto bail;
    }
    // Now that we know the buffer size, get the value.
    path = (LPTSTR) malloc(bufsize * sizeof(TCHAR));
    if (path == NULL)
        goto bail;
    n = GetEnvironmentVariable(TEXT ("PATH"), path, bufsize);
    if (n == 0 || n >= bufsize)
        goto bail;

    bufsize = _tcslen(dir) + 1 + _tcslen(path) + 1;
    value = (LPTSTR) malloc(bufsize * sizeof(TCHAR));
    if (value == NULL)
        goto bail;
    len = _sntprintf(value, bufsize, "%s;%s", dir, path);
    if (len < 0 || (DWORD) len >= bufsize)
        goto bail;

    rc = SetEnvironmentVariable(TEXT ("PATH"), value);
    if (rc == 0)
        goto bail;

    free(path);
    free(value);
    return 1;

bail:
    if (path != NULL)
        free(path);
    if (value != NULL)
        free(value);
    return 0;
}

// Returns 0 on failure and nonzero on success.
DWORD StartTorBrowser(void)
{
    TCHAR *TorDir;
    DWORD rc;
    // Put the Tor subdirectory at the beginning of PATH so that pluggable
    // transports (in their own subdirectory) can access DLLs.
    // https://trac.torproject.org/projects/tor/ticket/10845
    TorDir = GetSubdirectory(TEXT ("Tor"));
    if (TorDir == NULL)
        return 0;
    rc = PrependToPath(TorDir);
    free(TorDir);
    if (rc == 0)
        return 0;

    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    
    ZeroMemory ( &si, sizeof(si) );  
    si.cb = sizeof(si);
    ZeroMemory ( &pi, sizeof(pi) );

    TCHAR *ProgramToStart;
    ProgramToStart = TEXT ("Browser\\firefox.exe -no-remote -profile .\\Data\\Browser\\profile.default\\");

    return CreateProcess( NULL, ProgramToStart, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi );
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    if (!StartTorBrowser())
    {
         MessageBox ( NULL, TEXT ("Unable to start Tor Browser"), NULL, MB_OK);
         return -1;
    }

    return 0;
}
