module.exports = {
    uiPort: process.env.PORT || 1880,
    mqttReconnectTime: 15000,
    serialReconnectTime: 15000,
    debugMaxLength: 1000,
    adminAuth: {
        type: "credentials",
        users: [{
            username: "paul",
            password: "$2a$08$e3wQ6RDLLIiUvKZM0F5yM.3U33IZK7SCJZDZDSzpJY6wZ4QklkrO2",
            permissions: "*"
        }]
    },
    httpNodeAuth: {user:"api",pass:"$2a$08$lZj/Z2Uk2tXr5knBYaAOlumyc0un3lBt00LxW/79pla23i.NE2XAq"},
    httpStaticAuth: {user:"api",pass:"$2a$08$lZj/Z2Uk2tXr5knBYaAOlumyc0un3lBt00LxW/79pla23i.NE2XAq"},
    requireHttps: true,
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    },

    editorTheme: {
        projects: {
            // To enable the Projects feature, set this value to true
            enabled: false
        }
    }
}

