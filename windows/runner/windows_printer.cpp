#include "windows_printer.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <winspool.h>

#include <algorithm>
#include <cctype>
#include <cwctype>
#include <cmath>
#include <memory>
#include <sstream>
#include <string>
#include <variant>
#include <vector>

namespace {

std::string Utf16ToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return "";
  }

  const int size = WideCharToMultiByte(CP_UTF8, 0, value.data(),
                                       static_cast<int>(value.size()), nullptr,
                                       0, nullptr, nullptr);
  if (size <= 0) {
    return "";
  }

  std::string result(static_cast<size_t>(size), '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.data(), static_cast<int>(value.size()),
                      result.data(), size, nullptr, nullptr);
  return result;
}

std::wstring Utf8ToUtf16(const std::string& value) {
  if (value.empty()) {
    return L"";
  }

  const int size = MultiByteToWideChar(CP_UTF8, 0, value.data(),
                                       static_cast<int>(value.size()), nullptr,
                                       0);
  if (size <= 0) {
    return L"";
  }

  std::wstring result(static_cast<size_t>(size), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.data(), static_cast<int>(value.size()),
                      result.data(), size);
  return result;
}

std::wstring ToLower(std::wstring value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](wchar_t c) { return static_cast<wchar_t>(towlower(c)); });
  return value;
}

std::string LastErrorMessage(const std::string& action) {
  std::ostringstream stream;
  stream << action << " failed with Windows error " << GetLastError();
  return stream.str();
}

std::wstring GetDefaultPrinterName() {
  DWORD required = 0;
  GetDefaultPrinterW(nullptr, &required);
  if (required == 0) {
    return L"";
  }

  std::vector<wchar_t> buffer(static_cast<size_t>(required));
  if (!GetDefaultPrinterW(buffer.data(), &required)) {
    return L"";
  }

  return std::wstring(buffer.data());
}

bool EnumPrinterInfo(std::vector<BYTE>* buffer, DWORD* returned) {
  DWORD needed = 0;
  *returned = 0;
  EnumPrintersW(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, nullptr, 2,
                nullptr, 0, &needed, returned);
  if (needed == 0) {
    return false;
  }

  buffer->assign(static_cast<size_t>(needed), 0);
  return EnumPrintersW(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, nullptr,
                       2, buffer->data(), needed, &needed, returned);
}

flutter::EncodableList ListInstalledPrinters() {
  flutter::EncodableList printers;
  std::vector<BYTE> buffer;
  DWORD returned = 0;
  if (!EnumPrinterInfo(&buffer, &returned)) {
    return printers;
  }

  const std::wstring default_printer = GetDefaultPrinterName();
  const PRINTER_INFO_2W* printer_info =
      reinterpret_cast<const PRINTER_INFO_2W*>(buffer.data());

  for (DWORD i = 0; i < returned; ++i) {
    if (printer_info[i].pPrinterName == nullptr) {
      continue;
    }

    const std::wstring printer_name(printer_info[i].pPrinterName);
    const std::wstring port_name =
        printer_info[i].pPortName == nullptr ? L"" : printer_info[i].pPortName;
    const std::wstring driver_name = printer_info[i].pDriverName == nullptr
                                         ? L""
                                         : printer_info[i].pDriverName;

    flutter::EncodableMap printer;
    printer[flutter::EncodableValue("name")] =
        flutter::EncodableValue(Utf16ToUtf8(printer_name));
    printer[flutter::EncodableValue("portName")] =
        flutter::EncodableValue(Utf16ToUtf8(port_name));
    printer[flutter::EncodableValue("driverName")] =
        flutter::EncodableValue(Utf16ToUtf8(driver_name));
    printer[flutter::EncodableValue("isDefault")] =
        flutter::EncodableValue(!default_printer.empty() &&
                                printer_name == default_printer);
    printers.push_back(flutter::EncodableValue(printer));
  }

  return printers;
}

bool CanOpenPrinter(const std::wstring& printer_name) {
  if (printer_name.empty()) {
    return false;
  }

  HANDLE printer = nullptr;
  const BOOL opened =
      OpenPrinterW(const_cast<LPWSTR>(printer_name.c_str()), &printer, nullptr);
  if (opened && printer != nullptr) {
    ClosePrinter(printer);
  }
  return opened;
}

std::wstring ResolvePrinterName(const std::wstring& requested) {
  if (requested.empty()) {
    return GetDefaultPrinterName();
  }

  if (CanOpenPrinter(requested)) {
    return requested;
  }

  std::vector<BYTE> buffer;
  DWORD returned = 0;
  if (!EnumPrinterInfo(&buffer, &returned)) {
    return requested;
  }

  const std::wstring requested_lower = ToLower(requested);
  const PRINTER_INFO_2W* printer_info =
      reinterpret_cast<const PRINTER_INFO_2W*>(buffer.data());

  for (DWORD i = 0; i < returned; ++i) {
    if (printer_info[i].pPrinterName == nullptr) {
      continue;
    }

    const std::wstring printer_name(printer_info[i].pPrinterName);
    const std::wstring port_name =
        printer_info[i].pPortName == nullptr ? L"" : printer_info[i].pPortName;
    const std::wstring combined_lower =
        ToLower(printer_name + L" " + port_name);

    if (combined_lower.find(requested_lower) != std::wstring::npos) {
      return printer_name;
    }
  }

  return requested;
}

bool WriteRawToPrinter(const std::wstring& requested_printer,
                       const std::vector<uint8_t>& data,
                       std::string* error_message) {
  if (data.empty()) {
    *error_message = "No print data was provided.";
    return false;
  }

  const std::wstring printer_name = ResolvePrinterName(requested_printer);
  if (printer_name.empty()) {
    *error_message = "No default Windows printer is configured.";
    return false;
  }

  HANDLE printer = nullptr;
  if (!OpenPrinterW(const_cast<LPWSTR>(printer_name.c_str()), &printer,
                    nullptr)) {
    *error_message = LastErrorMessage("OpenPrinter");
    return false;
  }

  DOC_INFO_1W doc_info;
  doc_info.pDocName = const_cast<LPWSTR>(L"Velocity POS Receipt");
  doc_info.pOutputFile = nullptr;
  doc_info.pDatatype = const_cast<LPWSTR>(L"RAW");

  const DWORD job_id =
      StartDocPrinterW(printer, 1, reinterpret_cast<LPBYTE>(&doc_info));
  if (job_id == 0) {
    *error_message = LastErrorMessage("StartDocPrinter");
    ClosePrinter(printer);
    return false;
  }

  bool ok = true;
  if (!StartPagePrinter(printer)) {
    *error_message = LastErrorMessage("StartPagePrinter");
    ok = false;
  }

  DWORD written = 0;
  if (ok &&
      !WritePrinter(printer, const_cast<uint8_t*>(data.data()),
                    static_cast<DWORD>(data.size()), &written)) {
    *error_message = LastErrorMessage("WritePrinter");
    ok = false;
  }

  if (ok && written != static_cast<DWORD>(data.size())) {
    *error_message = "Windows accepted only part of the print data.";
    ok = false;
  }

  if (ok && !EndPagePrinter(printer)) {
    *error_message = LastErrorMessage("EndPagePrinter");
    ok = false;
  }

  if (!EndDocPrinter(printer) && ok) {
    *error_message = LastErrorMessage("EndDocPrinter");
    ok = false;
  }

  ClosePrinter(printer);
  return ok;
}

bool PrintTextWithDriver(const std::wstring& requested_printer,
                         const std::wstring& text,
                         std::string* error_message) {
  if (text.empty()) {
    *error_message = "No print text was provided.";
    return false;
  }

  const std::wstring printer_name = ResolvePrinterName(requested_printer);
  if (printer_name.empty()) {
    *error_message = "No default Windows printer is configured.";
    return false;
  }

  HDC printer_dc = CreateDCW(L"WINSPOOL", printer_name.c_str(), nullptr, nullptr);
  if (printer_dc == nullptr) {
    *error_message = LastErrorMessage("CreateDC");
    return false;
  }

  DOCINFOW doc_info = {};
  doc_info.cbSize = sizeof(DOCINFOW);
  doc_info.lpszDocName = L"Velocity POS Receipt";

  if (StartDocW(printer_dc, &doc_info) <= 0) {
    *error_message = LastErrorMessage("StartDoc");
    DeleteDC(printer_dc);
    return false;
  }

  const int dpi_y = GetDeviceCaps(printer_dc, LOGPIXELSY);
  const int page_width = GetDeviceCaps(printer_dc, HORZRES);
  const int page_height = GetDeviceCaps(printer_dc, VERTRES);
  const int margin_x = std::max(page_width / 20, 80);
  const int margin_y = std::max(page_height / 25, 80);
  const int font_height = -MulDiv(10, dpi_y, 72);

  HFONT font = CreateFontW(font_height, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
                           DEFAULT_CHARSET, OUT_OUTLINE_PRECIS,
                           CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                           FIXED_PITCH | FF_MODERN, L"Consolas");
  HGDIOBJ old_font = nullptr;
  if (font != nullptr) {
    old_font = SelectObject(printer_dc, font);
  }

  TEXTMETRICW metrics = {};
  GetTextMetricsW(printer_dc, &metrics);
  const int line_height = metrics.tmHeight + metrics.tmExternalLeading + 6;
  int y = margin_y;

  bool ok = true;
  if (StartPage(printer_dc) <= 0) {
    *error_message = LastErrorMessage("StartPage");
    ok = false;
  }

  size_t start = 0;
  while (ok && start <= text.length()) {
    const size_t end = text.find(L'\n', start);
    std::wstring line =
        end == std::wstring::npos ? text.substr(start) : text.substr(start, end - start);
    if (!line.empty() && line.back() == L'\r') {
      line.pop_back();
    }

    if (y + line_height > page_height - margin_y) {
      if (EndPage(printer_dc) <= 0 || StartPage(printer_dc) <= 0) {
        *error_message = LastErrorMessage("Page break");
        ok = false;
        break;
      }
      y = margin_y;
    }

    if (!TextOutW(printer_dc, margin_x, y, line.c_str(),
                  static_cast<int>(line.length()))) {
      *error_message = LastErrorMessage("TextOut");
      ok = false;
      break;
    }

    y += line_height;

    if (end == std::wstring::npos) {
      break;
    }
    start = end + 1;
  }

  if (ok && EndPage(printer_dc) <= 0) {
    *error_message = LastErrorMessage("EndPage");
    ok = false;
  }

  if (EndDoc(printer_dc) <= 0 && ok) {
    *error_message = LastErrorMessage("EndDoc");
    ok = false;
  }

  if (old_font != nullptr) {
    SelectObject(printer_dc, old_font);
  }
  if (font != nullptr) {
    DeleteObject(font);
  }
  DeleteDC(printer_dc);

  return ok;
}

const flutter::EncodableValue* FindArg(const flutter::EncodableMap& args,
                                       const char* key) {
  const auto it = args.find(flutter::EncodableValue(key));
  return it == args.end() ? nullptr : &it->second;
}

}  // namespace

void RegisterWindowsPrinterChannel(flutter::BinaryMessenger* messenger) {
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel;
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "windows_printer",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() == "listPrinters") {
          result->Success(flutter::EncodableValue(ListInstalledPrinters()));
          return;
        }

        if (call.method_name() == "printRaw") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args == nullptr) {
            result->Error("bad_args", "Expected a map of print arguments.");
            return;
          }

          const auto* printer_value = FindArg(*args, "printerName");
          const auto* data_value = FindArg(*args, "data");
          const auto* printer_name =
              printer_value == nullptr
                  ? nullptr
                  : std::get_if<std::string>(printer_value);
          const auto* data =
              data_value == nullptr
                  ? nullptr
                  : std::get_if<std::vector<uint8_t>>(data_value);

          if (printer_name == nullptr || data == nullptr) {
            result->Error("bad_args",
                          "Expected printerName and Uint8List data.");
            return;
          }

          std::string error_message;
          if (!WriteRawToPrinter(Utf8ToUtf16(*printer_name), *data,
                                 &error_message)) {
            result->Error("print_failed", error_message);
            return;
          }

          result->Success(flutter::EncodableValue(true));
          return;
        }

        if (call.method_name() == "printText") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args == nullptr) {
            result->Error("bad_args", "Expected a map of print arguments.");
            return;
          }

          const auto* printer_value = FindArg(*args, "printerName");
          const auto* text_value = FindArg(*args, "text");
          const auto* printer_name =
              printer_value == nullptr ? nullptr : std::get_if<std::string>(printer_value);
          const auto* text =
              text_value == nullptr ? nullptr : std::get_if<std::string>(text_value);

          if (printer_name == nullptr || text == nullptr) {
            result->Error("bad_args", "Expected printerName and text.");
            return;
          }

          std::string error_message;
          if (!PrintTextWithDriver(Utf8ToUtf16(*printer_name), Utf8ToUtf16(*text),
                                   &error_message)) {
            result->Error("print_failed", error_message);
            return;
          }

          result->Success(flutter::EncodableValue(true));
          return;
        }

        result->NotImplemented();
      });
}
