// FactoryX
//
// Copyright ©2003 - 2012 by FactoryX, Sefferweich Germany (EU)
// Project: Media Foundation - MFPack
// Module: WASAPI interfaces - AudioClient.pas
// Kind: Pascal Unit
// Release date: 04-05-2012
// Language: ENU
//
// Version: 1.0.0.1
// Description: Requires Windows Vista or later. 
// 
// Intiator(s): Tony (maXcomX), Peter (OzShips) 
// 
// LastEdited by: Tony
// EditDate: updt 010412a
//
// Remarks:
//
//          Delphi : The IUnknown entries of functions should be casted like this:
//                   IUnknown(Pointer), IUnknown(Object), IUnknown(Nil) etc.
//
// Related objects: -
// Related projects: -
// Known Issues: -
// Compiler version: 23, updt 4
// Todo: These should be inmplemented in a class, for now, it works.
// =============================================================================
// Source: audioclient.h
//
// Copyright (c) 1997-2012 Microsoft Corporation. All rights reserved
//==============================================================================
// The contents of this file are subject to the Mozilla Public
// License Version 1.1 (the "License"). you may not use this file
// except in compliance with the License. You may obtain a copy of
// the License at http://www.mozilla.org/MPL/MPL-1.1.html
//
// Software distributed under the License is distributed on an
// "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
// implied. See the License for the specific language governing
// rights and limitations under the License.
//==============================================================================

unit AudioClient;

{$MINENUMSIZE 4}
{$WEAKPACKAGEUNIT}

interface

uses
	Windows, ActiveX, ComObj, AudioSessionTypes;


const
	IID_IAudioClient           : TGUID = '{1CB9AD4C-DBFA-4c32-B178-C2F568A703B2}';
        IID_IAudioRenderClient     : TGUID = '{F294ACFC-3146-4483-A7BF-ADDCA7C260E2}';
	IID_IAudioCaptureClient    : TGUID = '{C8ADBD64-E71E-48a0-A4DE-185C395CD317}';
	IID_IAudioClock   	   : TGUID = '{CD63314F-3FBA-4a1b-812C-EF96358728E7}';
        IID_IAudioClock2 	   : TGUID = '{6f49ff73-6727-49ac-a008-d98cf5e70048}';
	IID_IAudioClockAdjustment  : TGUID = '{f6e4c0a0-46d9-4fb8-be21-57a3ef2b626c}';
	IID_ISimpleAudioVolume     : TGUID = '{87CE5498-68D6-44E5-9215-6DA47EF883D8}';
	IID_IAudioStreamVolume 	   : TGUID = '{93014887-242D-4068-8A15-CF5E93B90FE3}';
	IID_IChannelAudioVolume    : TGUID = '{1C158861-B533-4B30-B1CF-E853E51C59B8}';


type
	//Private WAVEFORMATEX
	{$EXTERNALSYM WAVEFORMATEX}
	cwWAVEFORMATEX = record
		wFormatTag: WORD;
		nChannels: WORD;
		nSamplesPerSec: DWORD;
		nAvgBytesPerSec: DWORD;
		nBlockAlign: WORD;
		wBitsPerSample: WORD;
		cbSize: WORD;
	end;
  WAVEFORMATEX = cwWAVEFORMATEX;
	PWAVEFORMATEX = ^WAVEFORMATEX;

	//Private
type
	{$EXTERNALSYM REFERENCE_TIME}
	REFERENCE_TIME = LONGLONG;
	PReferenceTime = ^REFERENCE_TIME;

type
	//enum
	_AUDCLNT_BUFFERFLAG = (
          AUDCLNT_BUFFERFLAGS_DATA_DISCONTINUITY,
          AUDCLNT_BUFFERFLAGS_SILENT,
          AUDCLNT_BUFFERFLAGS_TIMESTAMP_ERROR
        );
        _AUDCLNT_BUFFERFLAGS=set of _AUDCLNT_BUFFERFLAG;

type
	//Forward Interface Declarations
	IAudioClient = interface;
	IAudioRenderClient = interface;
	IAudioCaptureClient = interface;
	IAudioClock = interface;
	IAudioClockAdjustment = interface;
	IAudioClock2 = interface;
  ISimpleAudioVolume = interface;
	IAudioStreamVolume = interface;
  IChannelAudioVolume = interface;


  //enables a client to create and initialize an audio stream between an audio application
  //and the audio engine (for a shared-mode stream) or the hardware buffer of an
  //audio endpoint device (for an exclusive-mode stream).
(*	IAudioClient = interface(IUnknown)   //wrong origonal mfpack version that declares methods in wrong order
	['{1CB9AD4C-DBFA-4c32-B178-C2F568A703B2}']
		function GetBufferSize(out pNumBufferFrames: UINT32): HResult; stdcall;
		function GetCurrentPadding(out pNumPaddingFrames: UINT32): HResult; stdcall;
		function GetDevicePeriod(out phnsDefaultDevicePeriod: REFERENCE_TIME; phnsMinimumDevicePeriod: REFERENCE_TIME): HResult; stdcall;
		function GetMixFormat(out ppDeviceFormat: PWaveFormatEx): HResult; stdcall;
		//The GetService method supports the following service interfaces: IAudioCaptureClient, IAudioClock, IAudioRenderClient,
		//IAudioSessionControl, IAudioStreamVolume, IChannelAudioVolume, IMFTrustedOutput, ISimpleAudioVolume.
		//Since Windows 7 the new interface indentifier IID_IMFTrustedOutput has been added, but is not implemented here.
		function GetService(const riid: REFIID; out ppv: Pointer): HResult; stdcall;
		function GetStreamLatency(out phnsLatency: REFERENCE_TIME): HResult; stdcall;
		function Initialize(ShareMode: AUDCLNT_SHAREMODE; StreamFlags: Dword; hnsBufferDuration: REFERENCE_TIME; hnsPeriodicity: REFERENCE_TIME; pFormat: PWaveFormatEx; AudioSessionGuid: LPCGUID): HResult; stdcall;
		function IsFormatSupported(ShareMode: AUDCLNT_SHAREMODE; pFormat: PWaveFormatEx; ppClosestMatch: pointer): HResult; stdcall;
		function Reset(): HResult; stdcall;
		function SetEventHandle(const eventHandle: HANDLE): HResult; stdcall;
		function Start(): HResult; stdcall;
		function Stop(): HResult; stdcall;
	end; *)

        IAudioClient = interface(IUnknown)
	['{1CB9AD4C-DBFA-4c32-B178-C2F568A703B2}']
		function Initialize(ShareMode: AUDCLNT_SHAREMODE; StreamFlags: Dword; hnsBufferDuration: REFERENCE_TIME; hnsPeriodicity: REFERENCE_TIME; pFormat: PWaveFormatEx; AudioSessionGuid: PGUID): HResult; stdcall;
		function GetBufferSize(out pNumBufferFrames: UINT32): HResult; stdcall;
		function GetStreamLatency(out phnsLatency: REFERENCE_TIME): HResult; stdcall;
		function GetCurrentPadding(out pNumPaddingFrames: UINT32): HResult; stdcall;
		function IsFormatSupported(ShareMode: AUDCLNT_SHAREMODE; pFormat: PWaveFormatEx; ppClosestMatch: pointer): HResult; stdcall;
		function GetMixFormat(out ppDeviceFormat: PWaveFormatEx): HResult; stdcall;
		function GetDevicePeriod(out phnsDefaultDevicePeriod,phnsMinimumDevicePeriod: REFERENCE_TIME): HResult; stdcall;
		function Start(): HResult; stdcall;
		function Stop(): HResult; stdcall;
		function Reset(): HResult; stdcall;
		function SetEventHandle(const eventHandle: THANDLE): HResult; stdcall;
		//The GetService method supports the following service interfaces: IAudioCaptureClient, IAudioClock, IAudioRenderClient,
		//IAudioSessionControl, IAudioStreamVolume, IChannelAudioVolume, IMFTrustedOutput, ISimpleAudioVolume.
		//Since Windows 7 the new interface indentifier IID_IMFTrustedOutput has been added, but is not implemented here.
		function GetService(const riid: TGUID; out ppv: IUnknown): HResult; stdcall;
	end;


  //Enables a client to write output data to a rendering endpoint buffer.
  IAudioRenderClient = interface(IUnknown)
	['{F294ACFC-3146-4483-A7BF-ADDCA7C260E2}']
		function GetBuffer(const NumFramesRequested: UINT; out ppData: pointer): HResult; stdcall;
		function ReleaseBuffer(const NumFramesWritten: UINT32; const dwFlags: _AUDCLNT_BUFFERFLAGS): HResult; stdcall;
	end;

  //Enables a client to read input data from a capture endpoint buffer.
	IAudioCaptureClient = interface(IUnknown)
	['{C8ADBD64-E71E-48a0-A4DE-185C395CD317}']
		function GetBuffer(out ppData: pointer; out pNumFramesToRead: UINT32; out pdwFlags: DWord; out pu64DevicePosition: Int64; out pu64QPCPosition: Int64): HResult; stdcall;
		function ReleaseBuffer(const NumFramesRead: UINT32): HResult; stdcall;
		function GetNextPacketSize(out pNumFramesInNextPacket: UINT32): HResult; stdcall;
	end;

  //>=Vista
  //Enables a client to monitor a stream's data rate and the current position in the stream.
	IAudioClock = interface(IUnknown)
	['{CD63314F-3FBA-4a1b-812C-EF96358728E7}']
		function GetFrequency(out pu64Frequency: Int64): HResult; stdcall;
		function GetPosition(out pu64Position: Int64; out pu64QPCPosition: Int64): HResult; stdcall;
		function GetCharacteristics(pdwCharacteristics: DWord): HResult; stdcall;
	end;

  //>= Windows 7
  //Is used to get the current device position.
  IAudioClock2 = interface(IUnknown)
	['{6f49ff73-6727-49ac-a008-d98cf5e70048}']
		function GetDevicePosition(out DevicePosition: UINT64; out QPCPosition: UINT64): HResult; stdcall;
	end;

  //>= Windows 7
  //Is used to adjust the sample rate of a stream.
	IAudioClockAdjustment = interface(IUnknown)
	['{f6e4c0a0-46d9-4fb8-be21-57a3ef2b626c}']
		//Sets the sample rate of a stream, in frames per second.
		function SetSampleRate(const flSampleRate: Single): HResult; stdcall;
	end;

  ISimpleAudioVolume = interface(IUnknown)
	['{87CE5498-68D6-44E5-9215-6DA47EF883D8}']
    function SetMasterVolume(const fLevel: Single; const EventContext: PGUID): HResult; stdcall;
    function GetMasterVolume(out pfLevel: Single): HResult; stdcall;
    function SetMute(const bMute: Boolean; EventContext: PGUID): HResult; stdcall;
    function GetMute(out pbMute: Boolean): HResult; stdcall;
  end;

  //
	IAudioStreamVolume = interface(IUnknown)
	['{93014887-242D-4068-8A15-CF5E93B90FE3}']
		function GetChannelCount(out pdwCount: UINT32): HResult; stdcall;
		function SetChannelVolume(const dwIndex: UINT32; const fLevel: Single): HResult; stdcall;
		function GetChannelVolume(const dwIndex: UINT32; out pfLevel: Single): HResult; stdcall;
		function SetAllVolumes(const dwCount: UINT32; const pfVolumes: Single): HResult; stdcall;
		function GetAllVolumes(const dwCount: UINT32; out pfVolumes: Single): HResult; stdcall;
	end;

	IChannelAudioVolume = interface(IUnknown)
	['{1C158861-B533-4B30-B1CF-E853E51C59B8}']
		function GetChannelCount(out pdwCount: UINT32): HResult; stdcall;
		function SetChannelVolume(const dwIndex: UINT32; const fLevel: Single; EventContext: PGUID): HResult; stdcall;
		function GetChannelVolume(const dwIndex: UINT32; pfLevel: Single): HResult; stdcall;
		function SetAllVolumes(const dwCount: UINT32; const pfVolumes: Single; const EventContext: PGUID): HResult; stdcall;
		function GetAllVolumes(const dwCount: UINT32; out pfVolumes: Single): HResult; stdcall;
	end;

const
  AUDCLNT_E_NOT_INITIALIZED             = $88890001;
  AUDCLNT_E_ALREADY_INITIALIZED         = $88890002;
  AUDCLNT_E_WRONG_ENDPOINT_TYPE         = $88890003;
  AUDCLNT_E_DEVICE_INVALIDATED          = $88890004;
  AUDCLNT_E_NOT_STOPPED                 = $88890005;
  AUDCLNT_E_BUFFER_TOO_LARGE            = $88890006;
  AUDCLNT_E_OUT_OF_ORDER                = $88890007;
  AUDCLNT_E_UNSUPPORTED_FORMAT          = $88890008;
  AUDCLNT_E_INVALID_SIZE                = $88890009;
  AUDCLNT_E_DEVICE_IN_USE               = $8889000A;
  AUDCLNT_E_BUFFER_OPERATION_PENDING    = $8889000B;
  AUDCLNT_E_THREAD_NOT_REGISTERED       = $8889000C;
  AUDCLNT_E_EXCLUSIVE_MODE_NOT_ALLOWED  = $8889000E;
  AUDCLNT_E_ENDPOINT_CREATE_FAILED      = $8889000F;
  AUDCLNT_E_SERVICE_NOT_RUNNING         = $88890010;
  AUDCLNT_E_EVENTHANDLE_NOT_EXPECTED    = $88890011;
  AUDCLNT_E_EXCLUSIVE_MODE_ONLY         = $88890012;
  AUDCLNT_E_BUFDURATION_PERIOD_NOT_EQUAL= $88890013;
  AUDCLNT_E_EVENTHANDLE_NOT_SET         = $88890014;
  AUDCLNT_E_INCORRECT_BUFFER_SIZE       = $88890015;
  AUDCLNT_E_BUFFER_SIZE_ERROR           = $88890016;
  AUDCLNT_E_CPUUSAGE_EXCEEDED           = $88890017;
  AUDCLNT_E_BUFFER_ERROR                = $88890018;
  AUDCLNT_E_BUFFER_SIZE_NOT_ALIGNED     = $88890019;
  AUDCLNT_E_INVALID_DEVICE_PERIOD       = $88890020;
{  AUDCLNT_S_BUFFER_EMPTY                = AUDCLNT_SUCCESS ($001);
  AUDCLNT_S_THREAD_ALREADY_REGISTERED   = AUDCLNT_SUCCESS ($002);
  AUDCLNT_S_POSITION_STALLED            = AUDCLNT_SUCCESS ($003); }


  //Forward declarations of additiona functions

  //to use these functions, you should add jwaWinError.pas or WinError.pas -if available- to your uses clause.
  // function AUDCLNT_ERR(n: DWORD): DWORD;
  // function AUDCLNT_SUCCESS(n: DWORD): DWORD;

implementation

{const
	FACILITY_AUDCLNT                    = $889;

  AUDCLNT_E_NOT_INITIALIZED           = AUDCLNT_ERR($001);
	AUDCLNT_E_ALREADY_INITIALIZED       = AUDCLNT_ERR ($002);
  AUDCLNT_E_WRONG_ENDPOINT_TYPE       = AUDCLNT_ERR ($003);
  AUDCLNT_E_DEVICE_INVALIDATED        = AUDCLNT_ERR ($004);
	AUDCLNT_E_NOT_STOPPED               = AUDCLNT_ERR ($005);
  AUDCLNT_E_BUFFER_TOO_LARGE          = AUDCLNT_ERR ($006);
  AUDCLNT_E_OUT_OF_ORDER              = AUDCLNT_ERR ($007);
  AUDCLNT_E_UNSUPPORTED_FORMAT        = AUDCLNT_ERR ($008);
  AUDCLNT_E_INVALID_SIZE              = AUDCLNT_ERR ($009);
  AUDCLNT_E_DEVICE_IN_USE             = AUDCLNT_ERR ($00A);
  AUDCLNT_E_BUFFER_OPERATION_PENDING  = AUDCLNT_ERR ($00B);
  AUDCLNT_E_THREAD_NOT_REGISTERED     = AUDCLNT_ERR ($00C);
  AUDCLNT_E_EXCLUSIVE_MODE_NOT_ALLOWED= AUDCLNT_ERR ($00E);
  AUDCLNT_E_ENDPOINT_CREATE_FAILED    = AUDCLNT_ERR ($00F);
  AUDCLNT_E_SERVICE_NOT_RUNNING       = AUDCLNT_ERR ($010);
  AUDCLNT_E_EVENTHANDLE_NOT_EXPECTED  = AUDCLNT_ERR ($011);
  AUDCLNT_E_EXCLUSIVE_MODE_ONLY       = AUDCLNT_ERR ($012);
  AUDCLNT_E_BUFDURATION_PERIOD_NOT_EQUAL= AUDCLNT_ERR ($013);
  AUDCLNT_E_EVENTHANDLE_NOT_SET       = AUDCLNT_ERR ($014);
  AUDCLNT_E_INCORRECT_BUFFER_SIZE     = AUDCLNT_ERR ($015);
  AUDCLNT_E_BUFFER_SIZE_ERROR         = AUDCLNT_ERR ($016);
  AUDCLNT_E_CPUUSAGE_EXCEEDED         = AUDCLNT_ERR ($017);
  AUDCLNT_E_BUFFER_ERROR              = AUDCLNT_ERR ($018);
  AUDCLNT_E_BUFFER_SIZE_NOT_ALIGNED   = AUDCLNT_ERR ($019);
  AUDCLNT_E_INVALID_DEVICE_PERIOD     = AUDCLNT_ERR ($020);
  AUDCLNT_S_BUFFER_EMPTY              = AUDCLNT_SUCCESS ($001);
  AUDCLNT_S_THREAD_ALREADY_REGISTERED = AUDCLNT_SUCCESS ($002);
  AUDCLNT_S_POSITION_STALLED          = AUDCLNT_SUCCESS ($003);


//ERROR HANDLING
function AUDCLNT_ERR(n: DWORD): DWORD;
begin
  Result:= MAKE_HRESULT(SEVERITY_ERROR, FACILITY_AUDCLNT, n);
end;

function AUDCLNT_SUCCESS(n: DWORD): DWORD;
begin
  Result:= MAKE_SCODE(SEVERITY_SUCCESS, FACILITY_AUDCLNT, n);
end;
}

end.