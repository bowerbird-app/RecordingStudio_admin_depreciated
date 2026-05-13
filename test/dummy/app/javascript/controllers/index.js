import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Eager load FlatPack controllers
eagerLoadControllersFrom("controllers/flat_pack", application)
