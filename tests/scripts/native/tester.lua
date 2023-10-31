local scripts_dir = app.params.scripts_dir
local libs_dir = app.params.libs_dir

package.path = scripts_dir .. ";" .. package.path
package.cpath = libs_dir .. ";" .. package.cpath

local script = require(app.params.call)