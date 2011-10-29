GenomeSuite::Application.routes.draw do

  # The priority is based upon order of creation:
  # first created -> highest priority.

  ##Navigation
  #root :to => "home#index"
  root :to => "home#index"
  match '/faq' => 'help#faq', :as  => :faq
  match '/about' => 'help#about', :as  => :about
  match '/help' => 'help#index', :as  => :help
  match '/contact' => 'help#contact', :as  => :contact
  match 'sitemap' => 'help#sitemap', :as => :sitemap

  ##genome
  resources :bioentries do 
    get 'tracks'
  end
  resources :genes do
    get 'details', :on => :collection
  end
  resources :gene_models
  
  resources :locations
  resources :seqfeature_qualifier_values

  ##Browser
  resources :track_layouts
  resources :tracks
  match "fetchers/metadata"
  match "fetchers/base_counts"
  match "fetchers/gene_models"
  match "fetchers/genome"  
  match "generic_feature/gene_models"
  match "protein_sequence/genome"
  
  ##Experiments
  resources :assets, :only => [:show]
  resources :tools do
    get 'details', :on => :collection
    get 'smooth', :on => :collection
    post 'smooth', :on => :collection
  end
  resources :experiments do
    get 'asset_details', :on => :collection
  end
  resources :chip_chips do
    get 'details', :on => :collection
    get 'compute_peaks', :on => :member
    get 'initialize_experiment', :on => :member
  end
  resources :chip_seqs do
    get 'details', :on => :collection
    get 'compute_peaks', :on => :member
    get 'initialize_experiment', :on => :member
  end
  resources :synthetics do
    get 'details', :on => :collection
    get 'compute_peaks', :on => :member
    get 'initialize_experiment', :on => :member
  end
  resources :variants do
    collection do
      get 'details'
      get 'track_data'
      post 'reload_assets'
    end
    get 'initialize_experiment', :on => :member
  end
  
  ##Accounts
  devise_for :users
  resources :user, :controller => 'user' do
    post 'update_track_node', :on => :member
  end
  
  namespace :admin do
    root :controller => "admin", :action => "index"
    resources :users
    resources :roles
  end
end
