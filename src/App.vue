/** * @Description: 下载geoJson文件 * @Author: TSY * @CreateDate: 2018/9/5 9:04 * @email: t@tsy6.com */ <template>
  <div class="body">
    <div id="container"></div>
    <div class="echarts">
      <div id="map"></div>
    </div>
    <div class="tips" v-show="isShowTips"> 正在下载，请耐心等待。。。(可打开控制台查看进度详情) </div>
  </div>
</template>
<script>
import JSZip from "jszip";

export default {
  name: "demo",
  components: {},
  data() {
    return {
      isShowAD: true,
      nameType: "",
      cityName: "中国",
      areaCode: 10000,
      geoJsonData: "",
      echartsMap: null,
      map: null,
      uimap: null,
      district: null,
      polygons: [],
      cityCode: 100000,
      citySelect: null,
      districtSelect: null,
      opts: {},
      mapData: [],
      zip: {}, //打包zip
      codeList: [],
      loadedNode: {}, // 记录已加载项
      waitToLoadList: [],
      loadingThreads: new Array(8).fill(null), // 8个并发
      isShowTips: false, //是否显示下载提示
    };
  },
  mounted() {
    //实例化zip对象
    this.zip = new JSZip();

    this.citySelect = document.getElementById("city");
    this.districtSelect = document.getElementById("district");
    this.echartsMap = this.$echarts.init(document.getElementById("map"));
    this.echartsMap.on("click", this.echartsMapClick);

    // console.log(AMap.plugin, 'AMap');
    this.map = new AMap.Map("container", {
      resizeEnable: true,
      center: [116.30946, 39.937629],
      zoom: 3,
    });

    this.opts = {
      subdistrict: 1, //返回下一级行政区
      showbiz: false, //最后一级返回街道信息
    };

    AMap.plugin("AMap.DistrictSearch", () => {
      this.district = new AMap.DistrictSearch(this.opts);
      this.district.search("中国", (status, data) => {
        if (status === "complete") {
          this.getData(data.districtList[0], "", 100000);
        }
      });
    });
  },
  methods: {
    echartsMapClick(params) {
      //地图点击事件
      if (params.data.level == "street") return;
      //清除地图上所有覆盖物
      for (var i = 0, l = this.polygons.length; i < l; i++) {
        this.polygons[i].setMap(null);
      }
      this.cityName = params.data.name;
      this.cityCode = params.data.cityCode;
      this.district.setLevel(params.data.level); //行政区级别
      this.district.setExtensions("all");
      //行政区查询
      //按照adcode进行查询可以保证数据返回的唯一性
      this.district.search(this.cityCode, (status, result) => {
        if (status === "complete") {
          this.getData(
            result.districtList[0],
            params.data.level,
            this.cityCode
          );
        }
      });
    },
    loadMapData(areaCode) {
      AMapUI.loadUI(["geo/DistrictExplorer"], (DistrictExplorer) => {
        //创建一个实例
        var districtExplorer = (window.districtExplorer = new DistrictExplorer({
          eventSupport: true, //打开事件支持
          map: this.map,
        }));

        districtExplorer.loadAreaNode(areaCode, (error, areaNode) => {
          if (error) {
            console.error(error);
            return;
          }
          let mapJson = {};
          mapJson.type = "FeatureCollection";
          mapJson.features = areaNode.getSubFeatures();
          this.loadMap(this.cityName, mapJson);
          this.geoJsonData = mapJson;
        });
      });
    },
    showTips() {
      this.isShowTips = true;
      setTimeout(() => {
        this.isShowTips = false;
      }, 3000);
    },
    loadMap(mapName, data) {
      if (data) {
        this.$echarts.registerMap(mapName, data);
        var option = {
          visualMap: {
            type: "piecewise",
            pieces: [
              { max: 30, label: "安全", color: "#2c9a42" },
              { min: 30, max: 60, label: "警告", color: "#d08a00" },
              { min: 60, label: "危险", color: "#c23c33" },
            ],
            color: "#fff",
            textStyle: {
              color: "#fff",
            },
            visibility: "off",
          },
          series: [
            {
              name: "数据名称",
              type: "map",
              roam: false,
              mapType: mapName,
              selectedMode: "single",
              showLegendSymbol: false,
              visibility: "off",
              itemStyle: {
                normal: {
                  color: "#ccc",
                  areaColor: "#fff",
                  borderColor: "#fff",
                  borderWidth: 0.5,
                  label: {
                    show: true,
                    textStyle: {
                      color: "rgb(249, 249, 249)",
                    },
                  },
                },
                emphasis: {
                  areaColor: false,
                  borderColor: "#fff",
                  areaStyle: {
                    color: "#fff",
                  },
                  label: {
                    show: true,
                    textStyle: {
                      color: "rgb(249, 249, 249)",
                    },
                  },
                },
              },
              data: this.mapData,
            },
          ],
        };
        this.echartsMap.setOption(option);
      }
    },
    getData(data, level, adcode) {
      var subList = data.districtList;
      if (subList) {
        var curlevel = subList[0].level;
        if (curlevel === "street") {
          let mapJsonList = this.geoJsonData.features;
          let mapJson = {};
          for (let i in mapJsonList) {
            if (mapJsonList[i].properties.name == this.cityName) {
              mapJson.type = "FeatureCollection";
              mapJson.features = [].concat(mapJsonList[i]);
            }
          }
          this.mapData = [];
          this.mapData.push({
            name: this.cityName,
            value: Math.random() * 100,
            level: curlevel,
          });
          this.loadMap(this.cityName, mapJson);
          return;
        }

        this.mapData = [];
        for (var i = 0, l = subList.length; i < l; i++) {
          var name = subList[i].name;
          var cityCode = subList[i].adcode;
          this.mapData.push({
            name: name,
            value: Math.random() * 100,
            cityCode: cityCode,
            level: curlevel,
          });
        }
        this.loadMapData(adcode);
      }
    },
  },
};
</script>
<style lang="stylus" scoped>
* {
  font-size: 14px;
}

.body {
  display: flex;
  width: 100%;
  overflow: hidden;
  margin: 0
}

.map, .echarts {
  width: 0;
  flex: 1;
  overflow: hidden;
}

.echarts {
  background-size: 100% 100%;
}

#map {
  width: 100%;
  height: 100vh;
  overflow: hidden;
}

.tips {
  position: fixed;
  bottom: 30%;
  left: 40%;
  padding: 10px 15px;
  border-radius: 5px;
  color: #fff;
  background: rgba(0, 0, 0, 0.8);
  z-index: 999;
}

</style>
