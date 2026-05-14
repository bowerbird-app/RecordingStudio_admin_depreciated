import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import IconController from "controllers/flat_pack/icon_controller"

application.register("flat-pack--icon", IconController)

// Register icons eagerly so they still render even if another FlatPack
// controller fails to import later in the bulk load.
eagerLoadControllersFrom("controllers/flat_pack", application)
