# Be sure to restart your server when you modify this file.

#GenomeSuite::Application.config.session_store :cookie_store, :key => '_genome_suite_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
GenomeSuite::Application.config.session_store :active_record_store
GenomeSuite::Application.config.action_controller.session = {
   :session_key => '_genome_suite_session',
   :secret      => 'd0927b42add78c0f5c79a8363e228d383049150364e9dbd233aae2a4e3354a3d11fb80ff299851f51f8e0f2b8d7f8978a98e03971a85988e1300d9a5cd5275e8'
 }