# lita-translation

Language translation plugin that uses Microsoft's Translator API.

## Installation

Add lita-translation to your Lita instance's Gemfile:

``` ruby
gem "lita-translation"
```

## Configuration

This plugin requires you to obtain a client id and secret for [Microsoft's Translation API](http://www.microsoft.com/translator/api.aspx). Register an account at the [Microsoft Azure Marketplace](https://azure.microsoft.com), and then register an application that uses the translation API service.

### Required attributes

* `client_id` (String) - A human readable identifier for your client that you provide on registration.
* `client_secret` (String) - A key generated by Microsoft for your client.

### Example

```
Lita.configure do |config|
  config.handlers.translation.client_id = "my-translation-id"
  config.handlers.translation.client_secret = "some key"
end
```

## Usage

An OAuth token is automatically requested by the plugin whenever a fresh one is unavailable.

Microsoft uses ISO-639 codes to identify languages. Klingon is available.

* languages - List language codes supported by Microsoft's Translator API
* determine '[text]' - Determine language of the given text
* translate '[text]' to [code] (from [code]) - Translate the given text from one language to another
* translate me to [code] (from [code]) - Begin auto-translating all user's speech to the given language
* stop translating me - End any auto-translation

Source language is optional during translation. Microsoft will attempt to detect the source language if none is supplied.

## License

[MIT](http://opensource.org/licenses/MIT)
