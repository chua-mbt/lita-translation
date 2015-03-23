require 'json'

class MSTranslator
  OAUTH_URI = "https://datamarket.accesscontrol.windows.net/v2/OAuth2-13"
  API_URI = "https://api.microsofttranslator.com/V2/Ajax.svc/"

  REST_LANGCODES = "GetLanguagesForTranslate"
  REST_LANGNAMES = "GetLanguageNames"
  REST_DETECTION = "Detect"
  REST_TRANSLATE = "Translate"

  def initialize(clientId, clientSecret, http, redis)
    @clientId = clientId
    @clientSecret = clientSecret
    @http = http
    @redis = redis
  end

  def grabAccessToken()
    result = @http.post(
      OAUTH_URI,
      client_id: @clientId,
      client_secret: @clientSecret,
      scope: "http://api.microsofttranslator.com",
      grant_type: "client_credentials"
    )
    if result.status == 200
      raw = JSON.parse(result.body)
      @redis.set("token", raw["access_token"])
      @redis.set("start", Time.now)
      @redis.set("expiry", raw["expires_in"])
      true
    else
      false
    end
  end

  def staleToken?()
    start = @redis.get("start")
    expiry = @redis.get("expiry")
    if start.nil? || (Time.parse(start) + expiry.to_i) < Time.now
      return true
    end
    false
  end

  def apiSuccess?(result)
    if result.status != 200
      false
    else
      /ID=\d{4}\.V2_Json\.(\w+)\.\w{8}/.match(result.body).nil?
    end
  end

  def languageCodes()
    result = @http.get do |req|
      req.url API_URI+REST_LANGCODES
      req.headers['Authorization'] = "Bearer "+@redis.get("token")
    end
    if apiSuccess?(result)
      TranslationResult.new(
        true,
        JSON.parse(result.body.slice(3..result.body.length)).join(",")
      )
    else
      TranslationResult.new(
        false,
        result.body.slice(3..result.body.length)
      )
    end
  end

  def languageNames(codes)
    codes = '['+codes.split(",").map { |code| '"'+code+'"' }.join(",")+']'
    result = @http.get do |req|
      req.url API_URI+REST_LANGNAMES, {:locale => "en", :languageCodes => codes}
      req.headers['Authorization'] = "Bearer "+@redis.get("token")
    end
    if apiSuccess?(result)
      TranslationResult.new(
        true,
        JSON.parse(result.body.slice(3..result.body.length)).join(",")
      )
    else
      TranslationResult.new(
        false,
        result.body.slice(3..result.body.length)
      )
    end
  end

  def detect(text)
    result = @http.get do |req|
      req.url API_URI+REST_DETECTION, :text => text
      req.headers['Authorization'] = "Bearer "+@redis.get("token")
    end
    TranslationResult.new(apiSuccess?(result), result.body.slice(3..result.body.length))
  end

  def translate(text, to, from=nil)
    result = @http.get do |req|
      req.url API_URI+REST_TRANSLATE, :text => text, :from => from, :to => to, :contentType => "text/plain"
      req.headers['Authorization'] = "Bearer "+@redis.get("token")
    end
    TranslationResult.new(apiSuccess?(result), result.body.slice(3..result.body.length))
  end

end

class TranslationResult
  def initialize(success, message)
    @success = success
    @message = message
  end
  def success
    @success
  end
  def message
    @message
  end
end