require "lita/handlers/msTranslator"

module Lita
  module Handlers
    class Translation < Handler
      config :client_id, type: String, required: true
      config :client_secret, type: String, required: true

      def tokenAvailable?(response, translator)
        if translator.staleToken?
          response.reply(t("replies.access_token.attempt"))
          if translator.grabAccessToken
            response.reply(t("replies.access_token.success"))
            return true
          else
            response.reply(t("replies.access_token.fail"))
            return false
          end
        else
          return true
        end
      end

      route /^languages$/, :languages, help: {
        t("help.languages.usage") => t("help.languages.description")
      }
      def languages(response)
        translator = MSTranslator.new(config.client_id, config.client_secret, http, redis)
        if tokenAvailable?(response, translator)
          result = translator.languages
          if result.success
            response.reply(t("replies.languages"))
          else
            response.reply(t("replies.failure"))
          end
          response.reply(result.message)
        end
      end

      route /^determine '(.+)'$/, :determine, help: {
        t("help.determine.usage") => t("help.determine.description")
      }
      def determine(response)
        translator = MSTranslator.new(config.client_id, config.client_secret, http, redis)
        if tokenAvailable?(response, translator)
          result = translator.detect(response.matches.pop[0])
          if result.success
            code = result.message
            response.reply(t("replies.determine", code: code))
          else
            response.reply(t("replies.failure"))
            response.reply(result.message)
          end
        end
      end

      route /^translate '(.+)' to (\w+)( from (\w+))?$/, :translate, help: {
        t("help.translate.usage") => t("help.translate.description")
      }
      def translate(response)
        translator = MSTranslator.new(config.client_id, config.client_secret, http, redis)
        if tokenAvailable?(response, translator)
          text = response.matches.flatten[0]
          to = response.matches.flatten[1]
          from = response.matches.flatten[3]
          result = translator.translate(text, to, from)
          if result.success
            response.reply(t("replies.translate", translated: result.message))
          else
            response.reply(t("replies.failure"))
            response.reply(result.message)
          end
        end
      end

    end

    Lita.register_handler(Translation)
  end
end
