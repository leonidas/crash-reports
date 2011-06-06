#
# This file is part of Meego-QA-Dashboard
#
# Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#
APPROOT       = __dirname
SETTINGS_FILE = "settings.json"

require.paths.unshift './node_modules'
require.paths.push 'server'
require.paths.push 'server/js'

fs     = require('fs')
monmon = require('monmon').monmon

settings          = JSON.parse fs.readFileSync(APPROOT + "/" + SETTINGS_FILE)
settings.app.root = APPROOT

db  = monmon.use(settings.app.name)
app = require('app').create_app settings, db

app.listen(settings.server.port)

