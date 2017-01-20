module Mumukit::Auth::LoginProvider
  def self.from_env
    AuthStrategy.get_current
  end
end


class AuthStrategy
  extend ConfigurableGlobal

  def protect_from_forgery(controller)
    controller.protect_from_forgery with: :exception
  end

  def logout_redirection_url(controller)
    controller.after_logout_redirection_url
  end

  def html_badge
    ''
  end

  def auth_init_partial
    'layouts/auth_partials/null_partial.html.erb'
  end

  def self.get_current
    auth_strategy = Rails.configuration.auth_provider
    case auth_strategy
      when 'developer'
        AuthStrategy::DeveloperStrategy.new
      when 'saml'
        AuthStrategy::SamlStrategy.new
      when 'auth0'
        AuthStrategy::Auth0Strategy.new
      else
        raise "Unknown auth_strategy `#{auth_strategy}`"
    end
  end
end

class AuthStrategy::SamlStrategy < AuthStrategy
  def set_auth_provider(omniauth)
    File.open('./saml.crt', 'w') { |file| file.write(Rails.configuration.saml_idp_cert.gsub("\\n", "\n")) }
    omniauth.provider :saml,
                      # TODO: change the :assertion_consumer_service_url, the :issuer and the :slo_default_relay_state:
                      # =>  1. we can not call any Organization method since there is none instantiated yet and
                      # =>  2. we must use the absolut path to generate the right SAML metadata to set up the federation with the IdP
                      assertion_consumer_service_url: "#{Rails.configuration.saml_base_url}/auth/saml/callback",
                      single_logout_service_url: "#{Rails.configuration.saml_base_url}/auth/saml/slo",
                      issuer: "#{Rails.configuration.saml_base_url}/auth/saml",
                      idp_sso_target_url: Rails.configuration.saml_idp_sso_target_url,
                      idp_slo_target_url: Rails.configuration.saml_idp_slo_target_url,
                      slo_default_relay_state: Rails.configuration.saml_base_url,
                      idp_cert: File.read('./saml.crt'),
                      attribute_service_name: 'Mumuki',
                      request_attributes: [
                        {name: 'email', name_format: 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', friendly_name: 'Email address'},
                        {name: 'name', name_format: 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', friendly_name: 'Full name'},
                        {name: 'image', name_format: 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', friendly_name: 'Avatar image'}
                      ],
                      attribute_statements: {
                        name: [Rails.configuration.saml_translation_name || "name"],
                        email: [Rails.configuration.saml_translation_email || "email"],
                        image: [Rails.configuration.saml_translation_image || "image"]
                      }
  end

  def auth_link
    "href='/auth/saml/'"
  end

  def protect_from_forgery(controller)
    # FIXME this is big security issue
    # Do nothing (do not protect): the IdP calls the assertion_url via POST and without the CSRF token
  end

  def logout_redirection_url(controller)
    Organization.url_for('/auth/saml/spslo')
  end
end

class AuthStrategy::Auth0Strategy < AuthStrategy
  def set_auth_provider(omniauth)
    omniauth.provider :auth0,
                      Rails.configuration.auth0_client_id,
                      Rails.configuration.auth0_client_secret,
                      Rails.configuration.auth0_domain,
                      callback_path: '/auth/auth0/callback'
  end

  def auth_link
    'href="#" onclick="window.signin();"'
  end

  def auth_init_partial
    'layouts/auth_partials/auth0.init.html.erb'
  end

  def html_badge
    '<a href="https://auth0.com/" target="_blank"><img height="40" alt="JWT Auth for open source projects" src="//cdn.auth0.com/oss/badges/a0-badge-light.png"/></a>'.html_safe
  end
end
class AuthStrategy::DeveloperStrategy < AuthStrategy

  def set_auth_provider(omniauth)
    omniauth.provider :developer
  end

  def auth_link
    "href='/auth/developer'"
  end

  def protect_from_forgery(_controller)
  end
end


class AuthStrategy::Auth0Strategy < AuthStrategy
  def set_auth_provider(omniauth)
    omniauth.provider :auth0,
                      Rails.configuration.auth0_client_id,
                      Rails.configuration.auth0_client_secret,
                      Rails.configuration.auth0_domain,
                      callback_path: '/auth/auth0/callback'
  end

  def auth_link
    'href="#" onclick="window.signin();"'
  end

  def auth_init_partial
    'layouts/auth_partials/auth0.init.html.erb'
  end

  def html_badge
    '<a href="https://auth0.com/" target="_blank"><img height="40" alt="JWT Auth for open source projects" src="//cdn.auth0.com/oss/badges/a0-badge-light.png"/></a>'.html_safe
  end
end

class PostgresPermissionsPersistence
  def self.from_config
    new
  end

  def set!(uid, permissions)
    User.find_by(uid: uid).update!(permissions: permissions)
  end

  def get(uid)
    User.find_by(uid: uid)&.permissions || Mumukit::Auth::Permissions.parse({})
  end

  def close
  end

  def clean_env!
  end
end


Mumukit::Auth.configure do |c|
  c.login_provider = Mumukit::Auth::LoginProvider.from_env
  c.persistence_strategy = PostgresPermissionsPersistence.new

  # TODO remove those lines
  unless Rails.env.test?
    c.client_id = Rails.configuration.auth0_client_id
    c.client_secret = Rails.configuration.auth0_client_secret
  end
end
