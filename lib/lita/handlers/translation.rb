require "lita/handlers/msTranslator"

module Lita
  module Handlers
    class Translation < Handler
      config :client_id, type: String, required: true
      config :client_secret, type: String, required: true

      def updateStoredLang(codes, names)
        languages = {}
        codes.split(",").zip(names.split(",")).each { |pair|
          languages[pair[0]] = pair[1]
        }
        redis.set("languages", languages)
        languages
      end

      on :connected, :init_lang
      def init_lang(payload)
        translator = MSTranslator.new(config.client_id, config.client_secret, http, redis)
        if translator.staleToken?
          translator.grabAccessToken
        end

        result = translator.languageCodes
        if !result.success
          return
        end

        codes = result.message
        result = translator.languageNames(codes)
        if !result.success
          return
        end

        names = result.message
        updateStoredLang(codes, names)
      end

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
          codeResult = translator.languageCodes
          if !codeResult.success
            response.reply(t("replies.failure"))
            response.reply(codeResult.message)
            return
          end

          nameResult = translator.languageNames(codeResult.message)
          if !nameResult.success
            response.reply(t("replies.failure"))
            response.reply(nameResult.message)
            return
          end

          languages = updateStoredLang(codeResult.message, nameResult.message)
          response.reply_privately(t("replies.languages"))
          languages.each{ |code, name|
            response.reply_privately("#{code}(#{name})")
          }
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

      route /^translate me to ([-\w]+)( from ([-\w]+))?$/, :auto_start, help: {
        t("help.auto_start.usage") => t("help.auto_start.description")
      }
      def auto_start(response)
        translator = MSTranslator.new(config.client_id, config.client_secret, http, redis)
        if tokenAvailable?(response, translator)
          to = response.matches.flatten[0]
          from = response.matches.flatten[2]
          redis.set(response.user.id+":to", to)
          redis.set(response.user.id+":from", from)
          response.reply(t("replies.auto_start", code: to, user: response.user.name))
        end
      end

      route /^stop translating me$/, :auto_end, help: {
        t("help.auto_end.usage") => t("help.auto_end.description")
      }
      def auto_end(response)
        redis.del(response.user.id+":to")
        redis.del(response.user.id+":from")
        response.reply(t("replies.auto_end", user: response.user.name))
      end

      route /^translate '(.+)' to ([-\w]+)( from ([-\w]+))?$/, :tran_lang, help: {
        t("help.translate.usage") => t("help.translate.description")
      }
      def tran_lang(response)
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

      route /./, :monitor
      def monitor(response)
        if(!redis.get(response.user.id+":to").nil?)
          translator = MSTranslator.new(config.client_id, config.client_secret, http, redis)
          to = redis.get(response.user.id+":to")
          from = redis.get(response.user.id+":from")
          result = translator.translate(response.message.body, to, from)
          if result.success
            response.reply(t("replies.auto", user: response.user.name, translated: result.message))
          end
        end
      end

    end

    Lita.register_handler(Translation)
  end
end
