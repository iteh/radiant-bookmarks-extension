ActionController::Routing::Routes.draw do |map|

  map.with_options :path_prefix => '/admin/:content_locale' do  |lang|
    lang.namespace :admin do |admin|
      admin.resources :bookmarks
    end
  end

end