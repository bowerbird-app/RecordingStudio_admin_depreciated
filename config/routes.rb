# frozen_string_literal: true

RecordingStudioAdmin::Engine.routes.draw do
  get "pages", to: "pages#index"
  root "home#index"
end
