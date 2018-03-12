#include "stdafx.h"
#include <fstream>
#include <string>
#include <iostream>
#include <sstream>
#include <vector>

#include <atlbase.h>
#include <UrlHist.h>
#include <shlguid.h>

#include <tchar.h>
#include "Header.h"

#define _CRT_SECURE_NO_DEPRECATE
#pragma warning(disable : 4996) //_CRT_SECURE_NO_WARNINGS
// The same story with ISO.
// Do you want stricmp or _stricmp? I prefer stricmp.
// Once ISO will have to update standards.
#define _CRT_NONSTDC_NO_DEPRECATE
#define CACHE_BUFSIZE 4096

#include <windows.h>
#include <stdio.h>
#include <strsafe.h>

//*************************************************************
//
//  RegDelnodeRecurse()
//
//  Purpose:    Deletes a registry key and all its subkeys / values.
//
//  Parameters: hKeyRoot    -   Root key
//              lpSubKey    -   SubKey to delete
//
//  Return:     TRUE if successful.
//              FALSE if an error occurs.
//
//*************************************************************

BOOL RegDelnodeRecurse(HKEY hKeyRoot, LPTSTR lpSubKey, std::vector<std::string> strUrl)
{
	LPTSTR lpEnd;
	LONG lResult;
	TCHAR szName[MAX_PATH];
	HKEY hKey;
	FILETIME ftWrite;
	LPTSTR name = new TCHAR[1096];
	DWORD namesize;

	BYTE pdata[2048];
	namesize = 1096;
	DWORD dataSize;
	if (RegOpenKeyEx(hKeyRoot, lpSubKey, 0, KEY_ALL_ACCESS, &hKey) == ERROR_SUCCESS)
	{
		bool error = false;
		int idx = 0;
		size_t num = strUrl.size();
		size_t count = 0;
		while (RegEnumValue(hKey, idx, name, &namesize, NULL, NULL, pdata, &dataSize) == ERROR_SUCCESS && !error)
		{
			for (size_t i = 0; i < num; i++) {

				std::string tempstr = strUrl[i];

				char *str1 = &tempstr[0];
				size_t length = strlen(str1);
				WCHAR *wstr = new WCHAR[length + 1];
				MultiByteToWideChar(CP_THREAD_ACP, 0, str1, -1, wstr, (int)length + 1);

			
				//if (pdata != NULL) {
				//	if (StrStrI(pdata, str1) != NULL) {
				//		std::cout << "strstrI registry:" << name << std::endl;
				//		//std::wcout << "strstrI:" << wstr << std::endl;
				//		break;
				//	}
				//	else
				//	{
				//		count++;
				//		
				//	}

				//	if (count == num) {
				//		
				//		lResult = RegDeleteValue(hKey, name) ;
				//		if (lResult != ERROR_SUCCESS)
				//			return FALSE;
				//		std::cout << "delete typedUrl: " << name << std::endl;
				//	}
				//}
				delete[]pdata;
				delete[]wstr;
			}
			
			//idx++;
			
		}
		delete[] name;
		RegCloseKey(hKey);
	}
	return TRUE;
	
}

//*************************************************************
//
//  RegDelnode()
//
//  Purpose:    Deletes a registry key and all its subkeys / values.
//
//  Parameters: hKeyRoot    -   Root key
//              lpSubKey    -   SubKey to delete
//
//  Return:     TRUE if successful.
//              FALSE if an error occurs.
//
//*************************************************************

BOOL RegDelnode(std::vector<std::string> strUrl)
{
	#define MAX_KEY_LENGTH 255
	#define MAX_VALUE_NAME 16383

	TCHAR szName[MAX_PATH];
	HKEY hKey;
	FILETIME ftWrite;
	LPTSTR lpSubKey = TEXT("Software\\Microsoft\\Internet Explorer\\TypedURLs");

	TCHAR szDelKey[MAX_PATH * 2];

	StringCchCopy(szDelKey, MAX_PATH * 2, lpSubKey);
	if (RegOpenKeyEx(HKEY_CURRENT_USER, lpSubKey, 0, KEY_ALL_ACCESS, &hKey) == ERROR_SUCCESS)
	{

		bool error = false;
		int idx = 0;
		//LPTSTR name = new TCHAR[1096];
		//DWORD namesize;
		//namesize = 1096;
		char pdata[MAX_VALUE_NAME];
	
		DWORD dataSize;
		
		size_t num = strUrl.size();
		size_t count = 0;

		TCHAR    achKey[MAX_KEY_LENGTH];   // buffer for subkey name
		DWORD    cbName;                   // size of name string 
		TCHAR    achClass[MAX_PATH] = TEXT("");  // buffer for class name 
		DWORD    cchClassName = MAX_PATH;  // size of class string 
		DWORD    cSubKeys = 0;               // number of subkeys 
		DWORD    cbMaxSubKey;              // longest subkey size 
		DWORD    cchMaxClass;              // longest class string 
		DWORD    cValues;              // number of values for key 
		DWORD    cchMaxValue;          // longest value name 
		DWORD    cbMaxValueData;       // longest value data 
		DWORD    cbSecurityDescriptor; // size of security descriptor 
		FILETIME ftLastWriteTime;      // last write time 

		DWORD i, retCode;

		TCHAR  name[MAX_VALUE_NAME];
		DWORD namesize = MAX_VALUE_NAME;

		// Get the class name and the value count. 
		retCode = RegQueryInfoKey(
			hKey,                    // key handle 
			achClass,                // buffer for class name 
			&cchClassName,           // size of class string 
			NULL,                    // reserved 
			&cSubKeys,               // number of subkeys 
			&cbMaxSubKey,            // longest subkey size 
			&cchMaxClass,            // longest class string 
			&cValues,                // number of values for this key 
			&cchMaxValue,            // longest value name 
			&cbMaxValueData,         // longest value data 
			&cbSecurityDescriptor,   // security descriptor 
			&ftLastWriteTime);       // last write time 

		if (cValues)
		{
			printf("\nNumber of values: %d\n", cValues);

			for (i = 0, retCode = ERROR_SUCCESS; i<cValues; i++)
			{
				namesize = MAX_VALUE_NAME;
				dataSize = cbMaxValueData;
				name[0] = '\0';
				retCode = RegEnumValue(hKey, i, name, &namesize, NULL, NULL, (BYTE*)&pdata, &dataSize);
				if (retCode == ERROR_SUCCESS)
				{
					_tprintf(TEXT("(%d) %s %s\n "), i + 1, name, pdata);

						for (size_t i = 0; i < num; i++) {

							std::string tempstr = strUrl[i];

							char *str1 = &tempstr[0];
							size_t length = strlen(str1);
							WCHAR *wstr = new WCHAR[length + 1];
							WCHAR *wstrData = new WCHAR[strlen(pdata) + 1];
							MultiByteToWideChar(CP_THREAD_ACP, 0, str1, -1, wstr, (int)length + 1);
							MultiByteToWideChar(CP_THREAD_ACP, 0, pdata, -1, wstrData, strlen(pdata) + 1);

							std::wcout << "pdata" << pdata <<wstrData << std::endl;
							if (wstrData != NULL) {
								if (StrStrI(wstrData, wstr) != NULL) {
									std::wcout << "strstrI registry:" << name << std::endl;
									//std::wcout << "strstrI:" << wstr << std::endl;
									break;
								}
								else
								{
									count++;
									
								}

								if (count == num) {
																		
									if (RegDeleteValue(hKey, name) != ERROR_SUCCESS)
										return FALSE;
									std::wcout << "delete typedUrl: " << name << std::endl;
								}
							}
							delete[]wstrData;
							delete[]wstr;
						}

				}
			}
		}
		

		//while (RegEnumValue(hKey, idx, name, &namesize, NULL, NULL, (BYTE*)&pdata, &dataSize) == 0 && !error)
		//{
		//	for (size_t i = 0; i < num; i++) {

		//		std::string tempstr = strUrl[i];

		//		char *str1 = &tempstr[0];
		//		size_t length = strlen(str1);
		//		WCHAR *wstr = new WCHAR[length + 1];
		//		MultiByteToWideChar(CP_THREAD_ACP, 0, str1, -1, wstr, (int)length + 1);

		//		std::cout << "pdata" << pdata<< std::endl;
		//		//if (pdata != NULL) {
		//		//	if (StrStrI(pdata, str1) != NULL) {
		//		//		std::cout << "strstrI registry:" << name << std::endl;
		//		//		//std::wcout << "strstrI:" << wstr << std::endl;
		//		//		break;
		//		//	}
		//		//	else
		//		//	{
		//		//		count++;
		//		//		
		//		//	}

		//		//	if (count == num) {
		//		//		
		//		//		lResult = RegDeleteValue(hKey, name) ;
		//		//		if (lResult != ERROR_SUCCESS)
		//		//			return FALSE;
		//		//		std::cout << "delete typedUrl: " << name << std::endl;
		//		//	}
		//		//}
		//		delete[]pdata;
		//		delete[]wstr;
		//	}

		//	//idx++;

		//}
		delete[] name;
		RegCloseKey(hKey);
	}
	return TRUE;
	//return RegDelnodeRecurse(hKeyRoot, szDelKey, strUrl);

}



//////////////////////////////////////////////////////////////////////
// CCacheEntryInfo
//////////////////////////////////////////////////////////////////////
CCacheEntryInfo::CCacheEntryInfo()
{
	m_pInfo = NULL;
	m_dwSize = 0;
}

CCacheEntryInfo::~CCacheEntryInfo()
{
	Deallocate();
}

void CCacheEntryInfo::Allocate(int nSize)
{
	Deallocate();
	m_pInfo = (LPINTERNET_CACHE_ENTRY_INFO)new BYTE[nSize];
	m_dwSize = nSize;
	InitMemory();
}

void CCacheEntryInfo::Deallocate()
{
	if (m_pInfo)
	{
		delete[] m_pInfo;
		m_pInfo = NULL;
		m_dwSize = 0;
	}
}

void CCacheEntryInfo::InitMemory()
{
	if (m_pInfo && m_dwSize)
	{
		memset(m_pInfo, 0, m_dwSize);
	}
}

CCacheEntryInfo::operator LPINTERNET_CACHE_ENTRY_INFO()
{
	return m_pInfo;
}

DWORD CCacheEntryInfo::GetSize()
{
	return m_dwSize;
}

//////////////////////////////////////////////////////////////////////
// CUrlCacheHandle
//////////////////////////////////////////////////////////////////////
CUrlCacheHandle::CUrlCacheHandle()
{
	m_hCache = NULL;
}

CUrlCacheHandle::~CUrlCacheHandle()
{
}

void CUrlCacheHandle::Open(HANDLE h)
{
	Close();
	m_hCache = h;
}

void CUrlCacheHandle::Close()
{
	if (m_hCache)
	{
		::FindCloseUrlCache(m_hCache);
		m_hCache = NULL;
	}
}

CUrlCacheHandle::operator HANDLE()
{
	return m_hCache;
}

//////////////////////////////////////////////////////////////////////
// CUrlCacheEntry
//////////////////////////////////////////////////////////////////////
CUrlCacheEntry::CUrlCacheEntry()
{

}

CUrlCacheEntry::~CUrlCacheEntry()
{

}

LPINTERNET_CACHE_ENTRY_INFO CUrlCacheEntry::First(LPCTSTR lpszSearchPattern)
{
	//Close previous handle
	m_CacheHandle.Close();

	LPINTERNET_CACHE_ENTRY_INFO pInfoReturn = NULL;
	DWORD dwSize = CACHE_BUFSIZE;
	bool bContinue = true;

	//Contiue the make the first find until done with a large enough cache size
	do
	{
		if (m_CacheEntryInfo.GetSize() < dwSize)
		{
			m_CacheEntryInfo.Allocate(dwSize);
		}
		else
		{
			m_CacheEntryInfo.InitMemory();
		}

		HANDLE hCache = ::FindFirstUrlCacheEntry(lpszSearchPattern, m_CacheEntryInfo, &dwSize);

		if (hCache)
		{
			//Save the handle
			m_CacheHandle.Open(hCache);

			//Return info
			pInfoReturn = m_CacheEntryInfo;

			//Stop the loop
			bContinue = false;
		}
		else
		{
			if (ERROR_INSUFFICIENT_BUFFER == ::GetLastError())
			{
				//dwSize should now be set to the size needed
				bContinue = true;
			}
			else
			{
				//Some other error
				bContinue = false;
			}
		}
	} while (bContinue);

	return pInfoReturn;
}

LPINTERNET_CACHE_ENTRY_INFO CUrlCacheEntry::FirstCookie()
{
	return First(_T("cookie:"));
}

LPINTERNET_CACHE_ENTRY_INFO CUrlCacheEntry::FirstHistory()
{
	return First(_T("visited:"));
}

LPINTERNET_CACHE_ENTRY_INFO CUrlCacheEntry::Next()
{
	if (m_CacheHandle == NULL)
	{
		return NULL;
	}

	LPINTERNET_CACHE_ENTRY_INFO pInfoReturn = NULL;
	DWORD dwSize = m_CacheEntryInfo.GetSize();
	bool bContinue = true;

	//Contiue the make the first find until done with a large enough cache size
	do
	{
		if (m_CacheEntryInfo.GetSize() < dwSize)
		{
			m_CacheEntryInfo.Allocate(dwSize);
		}
		else
		{
			m_CacheEntryInfo.InitMemory();
		}

		BOOL bFindNext = ::FindNextUrlCacheEntry(m_CacheHandle, m_CacheEntryInfo, &dwSize);

		if (bFindNext)
		{
			//Return info
			pInfoReturn = m_CacheEntryInfo;

			//Stop the loop
			bContinue = false;
		}
		else
		{
			DWORD dwError = ::GetLastError();
			switch (dwError)
			{
			case ERROR_INSUFFICIENT_BUFFER:
				bContinue = true;
				break;
			case ERROR_NO_MORE_ITEMS:
				bContinue = false;
				break;
			default:
				//Some other error
				bContinue = false;
				break;
			}
		}
	} while (bContinue);

	return pInfoReturn;
}

LPINTERNET_CACHE_ENTRY_INFO CUrlCacheEntry::Get(LPCTSTR lpszUrlName)
{
	LPINTERNET_CACHE_ENTRY_INFO pInfoReturn = NULL;
	DWORD dwSize = m_CacheEntryInfo.GetSize();
	bool bContinue = true;

	//Contiue the make the first find until done with a large enough cache size
	do
	{
		if (m_CacheEntryInfo.GetSize() < dwSize)
		{
			m_CacheEntryInfo.Allocate(dwSize);
		}
		else
		{
			m_CacheEntryInfo.InitMemory();
		}

		BOOL bGet = ::GetUrlCacheEntryInfo(lpszUrlName, m_CacheEntryInfo, &dwSize);

		if (bGet)
		{
			//Return info
			pInfoReturn = m_CacheEntryInfo;

			//Stop the loop
			bContinue = false;
		}
		else
		{
			DWORD dwError = ::GetLastError();
			switch (dwError)
			{
			case ERROR_INSUFFICIENT_BUFFER:
				bContinue = true;
				break;
			case ERROR_FILE_NOT_FOUND:
				bContinue = false;
				break;
			default:
				//Some other error
				bContinue = false;
				break;
			}
		}
	} while (bContinue);

	return pInfoReturn;
}


//////////////////////////////////////////////////////////////////////
// CUrlCacheGroup
//////////////////////////////////////////////////////////////////////
CUrlCacheGroup::CUrlCacheGroup()
{
	Init();
}

CUrlCacheGroup::~CUrlCacheGroup()
{

}

void CUrlCacheGroup::Init()
{
	InitGroupID();
	m_hCacheGroup = NULL;
}

void CUrlCacheGroup::InitGroupID()
{
	memset(&m_GID, 0, sizeof(GROUPID));
}

GROUPID* CUrlCacheGroup::First(DWORD dwFilter)
{
	GROUPID* pGID = NULL;
	Init();

	m_hCacheGroup = ::FindFirstUrlCacheGroup(0, dwFilter, NULL, 0, &m_GID, NULL);

	if (m_hCacheGroup)
	{
		pGID = &m_GID;
	}

	return pGID;
}

GROUPID* CUrlCacheGroup::Next()
{
	GROUPID* pGID = NULL;

	if (!m_hCacheGroup)
	{
		return NULL;
	}

	if (::FindNextUrlCacheGroup(m_hCacheGroup, &m_GID, NULL))
	{
		pGID = &m_GID;
	}
	else
	{
		Init();
	}

	return pGID;
}

GROUPID* CUrlCacheGroup::First(LPINTERNET_CACHE_GROUP_INFO pInfo, DWORD dwFilter)
{
	GROUPID* pGID = First(dwFilter);

	if (pGID)
	{
		DWORD dwSize = sizeof(INTERNET_CACHE_GROUP_INFO);
		memset(pInfo, 0, dwSize);
		BOOL b = ::GetUrlCacheGroupAttribute(m_GID, 0, CACHEGROUP_ATTRIBUTE_GET_ALL, pInfo, &dwSize, NULL);
	}

	return pGID;
}

GROUPID* CUrlCacheGroup::Next(LPINTERNET_CACHE_GROUP_INFO pInfo)
{
	GROUPID* pGID = Next();

	if (pGID)
	{
		DWORD dwSize = sizeof(INTERNET_CACHE_GROUP_INFO);
		memset(pInfo, 0, dwSize);
		BOOL b = ::GetUrlCacheGroupAttribute(m_GID, 0, CACHEGROUP_ATTRIBUTE_GET_ALL, pInfo, &dwSize, NULL);
	}

	return pGID;
}

LPINTERNET_CACHE_ENTRY_INFO CUrlCacheGroup::FirstEntry(DWORD dwFilter)
{
	//Close previous handle
	m_CacheEntryHandle.Close();

	LPINTERNET_CACHE_ENTRY_INFO pInfoReturn = NULL;
	DWORD dwSize = CACHE_BUFSIZE;
	bool bContinue = true;

	//Contiue the make the first find until done with a large enough cache size
	do
	{
		if (m_CacheEntryInfo.GetSize() < dwSize)
		{
			m_CacheEntryInfo.Allocate(dwSize);
		}
		else
		{
			m_CacheEntryInfo.InitMemory();
		}

		HANDLE hCache = ::FindFirstUrlCacheEntryEx(NULL, 0, dwFilter, m_GID, m_CacheEntryInfo, &dwSize, NULL, NULL, NULL);

		if (hCache)
		{
			//Save the handle
			m_CacheEntryHandle.Open(hCache);

			//Return info
			pInfoReturn = m_CacheEntryInfo;

			//Stop the loop
			bContinue = false;
		}
		else
		{
			if (ERROR_INSUFFICIENT_BUFFER == ::GetLastError())
			{
				//dwSize should now be set to the size needed
				bContinue = true;
			}
			else
			{
				//Some other error
				bContinue = false;
			}
		}
	} while (bContinue);

	return pInfoReturn;
}

LPINTERNET_CACHE_ENTRY_INFO CUrlCacheGroup::NextEntry()
{
	if (m_CacheEntryHandle == NULL)
	{
		return NULL;
	}

	LPINTERNET_CACHE_ENTRY_INFO pInfoReturn = NULL;
	DWORD dwSize = m_CacheEntryInfo.GetSize();
	bool bContinue = true;

	//Contiue the make the first find until done with a large enough cache size
	do
	{
		if (m_CacheEntryInfo.GetSize() < dwSize)
		{
			m_CacheEntryInfo.Allocate(dwSize);
		}
		else
		{
			m_CacheEntryInfo.InitMemory();
		}

		BOOL bFindNext = ::FindNextUrlCacheEntryEx(m_CacheEntryHandle, m_CacheEntryInfo, &dwSize, NULL, NULL, NULL);

		if (bFindNext)
		{
			//Return info
			pInfoReturn = m_CacheEntryInfo;

			//Stop the loop
			bContinue = false;
		}
		else
		{
			DWORD dwError = ::GetLastError();
			switch (dwError)
			{
			case ERROR_INSUFFICIENT_BUFFER:
				bContinue = true;
				break;
			case ERROR_NO_MORE_ITEMS:
				bContinue = false;
				break;
			default:
				//Some other error
				bContinue = false;
				break;
			}
		}
	} while (bContinue);

	return pInfoReturn;
}

//////////////////////////////////////////////////////////////////////
// CUrlCacheUtil
//////////////////////////////////////////////////////////////////////
CUrlCacheUtil::CUrlCacheUtil()
{

}

CUrlCacheUtil::~CUrlCacheUtil()
{

}


bool CUrlCacheUtil::IsCacheTypeCookie(DWORD dwType)
{
	return ((dwType & COOKIE_CACHE_ENTRY) == COOKIE_CACHE_ENTRY);
}

bool CUrlCacheUtil::IsCacheTypeHistory(DWORD dwType)
{
	return ((dwType & URLHISTORY_CACHE_ENTRY) == URLHISTORY_CACHE_ENTRY);
}

bool CUrlCacheUtil::IsCacheTypeInternetFile(DWORD dwType)
{
	return (!IsCacheTypeCookie(dwType) && !IsCacheTypeHistory(dwType));
}

void CUrlCacheUtil::DeleteAll()
{
	DeleteAllEntries();
	DeleteAllGroups();
}

void CUrlCacheUtil::DeleteAllEntries()
{
	CUrlCacheEntry urlCacheEntry;
	LPINTERNET_CACHE_ENTRY_INFO pInfo = urlCacheEntry.First();
	while (pInfo)
	{
		DeleteEntry(pInfo);
		pInfo = urlCacheEntry.Next();
	}
	//DeleteHistory2();
}
void CUrlCacheUtil::DeleteCookies()
{
	CUrlCacheEntry urlCacheEntry;
	LPINTERNET_CACHE_ENTRY_INFO pInfo = urlCacheEntry.FirstCookie();
	while (pInfo)
	{
		DeleteEntry(pInfo);
		pInfo = urlCacheEntry.Next();
	}
}

void CUrlCacheUtil::DeleteHistory()
{
	CUrlCacheEntry urlCacheEntry;
	LPINTERNET_CACHE_ENTRY_INFO pInfo = urlCacheEntry.FirstHistory();
	while (pInfo)
	{
		DeleteEntry(pInfo);
		pInfo = urlCacheEntry.Next();
	}
	//DeleteHistory2();
}

void CUrlCacheUtil::DeleteInternetFiles()
{
	CUrlCacheEntry urlCacheEntry;
	LPINTERNET_CACHE_ENTRY_INFO pInfo = urlCacheEntry.First();
	while (pInfo)
	{
		if (IsCacheTypeInternetFile(pInfo->CacheEntryType))
		{
			DeleteEntry(pInfo);
		}
		pInfo = urlCacheEntry.Next();
	}
}


void CUrlCacheUtil::DeleteAllGroups()
{
	CUrlCacheGroup urlCG;
	GROUPID* pGID = urlCG.First();
	while (pGID)
	{
		DeleteGroup(pGID);

		pGID = urlCG.Next();
	}
}



bool CUrlCacheUtil::DeleteEntry(INTERNET_CACHE_ENTRY_INFO* pInfo)
{
	return (::DeleteUrlCacheEntry(pInfo->lpszSourceUrlName) ? true : false);
}

bool CUrlCacheUtil::DeleteGroup(GROUPID* pGID)
{
	return (::DeleteUrlCacheGroup(*pGID, CACHEGROUP_FLAG_FLUSHURL_ONDELETE, NULL) ? true : false);
}

void CUrlCacheUtil::DeleteHistory2()
{
	HRESULT res;
	//CoInitialize(NULL);
	CComPtr<IUrlHistoryStg2> pUrlHist2;
	res = pUrlHist2.CoCreateInstance(CLSID_CUrlHistory);//SID_SUrlHistory CLSID_CUrlHistory
	pUrlHist2->ClearHistory();
	pUrlHist2 = NULL;
	//CoUninitialize();
}

int main()
{

	std::ifstream file("siteList.txt");
	std::string str;
	
	if (!file.is_open())
		perror("error while opening file");

	std::vector<std::string> strUrl;
	


	
	while (getline(file, str))
	{
		strUrl.push_back(str);

	}

	if (file.bad())
		perror("error while reading file");

	size_t num = strUrl.size();
	//if (num == (size_t)0){

	//	std::cout << "No website is found in the input file." << std::endl;
		/*CUrlCacheUtil util;
		util.DeleteHistory();
		std::wcout << "********delete history. " << std::endl;
		util.DeleteAllEntries();
		*/
		//std::system("c:\\windows\\system32\\RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 4351 -nobanner");
	
	//	return 0;
	//}
	file.clear();
	file.seekg(file.beg);
	file.close();

	//delete typedurls
	BOOL bSuccess;

	bSuccess = RegDelnode(strUrl);



	//delete cache

	CUrlCacheEntry urlCacheEntry;
	CUrlCacheUtil util;
	LPINTERNET_CACHE_ENTRY_INFO pInfo = urlCacheEntry.FirstCookie();
	LPINTERNET_CACHE_ENTRY_INFO pInfoHistory = urlCacheEntry.FirstHistory();
	LPINTERNET_CACHE_ENTRY_INFO pInfoTf = urlCacheEntry.First();
	if (!pInfo && !pInfoHistory && !pInfoTf )
	{
		std::cout << "No cache is found"  << std::endl;
	}
	while (pInfo)
	{   
		//std::wcout << "start url:" << pInfo->lpszSourceUrlName << std::endl;
		
		size_t count = 0;
		for (size_t i = 0; i < num; i++) {
			
			std::string tempstr = strUrl[i];

			//std::cout << "readFile:" << tempstr << std::endl;
			
			char *str1 = &tempstr[0];
			size_t length = strlen(str1);
			WCHAR *wstr = new WCHAR[length + 1];
			MultiByteToWideChar(CP_THREAD_ACP, 0, str1, -1, wstr, (int)length + 1);

			LPCTSTR urlname = pInfo->lpszSourceUrlName;
			if (urlname != NULL) {
				if (StrStrI(urlname, wstr) != NULL) {
					//std::cout << "strstrI:" << urlname << std::endl;
					//std::wcout << "strstrI:" << wstr << std::endl;
					break;
				}
				else
				{
					count++;
					//std::cout << "count:" << count << std::endl;
				}

				if (count == num) {
					util.DeleteEntry(pInfo);
					std::wcout << "********delete cache :" << pInfo->lpszSourceUrlName << std::endl;

				}
			}
			delete[]wstr;
		}
		pInfo = urlCacheEntry.Next();

	}
	
	//while (pInfoHistory)
	//{
	//	size_t count = 0;
	//	for (size_t i = 0; i < num; i++) {
	//		//std::cout << strUrl[i] << std::endl;
	//		std::string tempstr = strUrl[i];

	//		LPCTSTR urlname = pInfoHistory->lpszSourceUrlName;
	//		//std::wcout << " History :" << urlname << std::endl;

	//		char *str1 = &tempstr[0];
	//		size_t length = strlen(str1);
	//		WCHAR *wstr = new WCHAR[length + 1];
	//		MultiByteToWideChar(CP_THREAD_ACP, 0, str1, -1, wstr, (int)length + 1);

	//		if (urlname != NULL) {
	//			if (StrStrI(urlname, wstr) != NULL) {
	//				break;
	//			}
	//			else
	//			{
	//				count++;
	//			}

	//			if (count == num) {
	//				if (util.IsCacheTypeHistory(pInfo->CacheEntryType))
	//				{
	//					util.DeleteEntry(pInfoHistory);
	//					std::wcout << "********delete History :" << pInfo->lpszSourceUrlName << std::endl;
	//				}
	//									
	//			}
	//		}
	//		delete[]wstr;
	//	}
	//	pInfoHistory = urlCacheEntry.Next();

	//}

	//while (pInfoTf)
	//{
	//	size_t count = 0;
	//	for (size_t i = 0; i < num; i++) {
	//		//std::cout << strUrl[i] << std::endl;
	//		std::string tempstr = strUrl[i];

	//		LPCTSTR urlname = pInfoTf->lpszSourceUrlName;

	//		char *str1 = &tempstr[0];
	//		size_t length = strlen(str1);
	//		WCHAR *wstr = new WCHAR[length + 1];
	//		MultiByteToWideChar(CP_THREAD_ACP, 0, str1, -1, wstr, (int)length + 1);

	//		if (urlname != NULL) {
	//			if (StrStrI(urlname, wstr) != NULL) {
	//				break;
	//			}
	//			else
	//			{
	//				count++;
	//			}

	//			if (count == num) {

	//				if (util.IsCacheTypeInternetFile(pInfoTf->CacheEntryType))
	//				{
	//					util.DeleteEntry(pInfoTf);
	//					std::wcout << "********delete temporary files :" << pInfo->lpszSourceUrlName << std::endl;
	//				}
	//			}
	//		}
	//		delete[]wstr;
	//	}

	//	pInfoTf = urlCacheEntry.Next();
	//}
	//

	return 0;
}
