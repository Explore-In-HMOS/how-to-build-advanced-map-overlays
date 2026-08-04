import { MapComponent, map, mapCommon } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  ArcButton, ArcButtonOptions, ArcButtonPosition, ArcButtonStyleMode
} from '@kit.ArkUI';

@Entry
@Component
struct Index {
  private mapController: map.MapComponentController | null = null;
  private mapEventManager: map.MapEventManager | null = null;
  private startPoint: mapCommon.LatLng = { latitude: 41.0082, longitude: 28.9784 };
  private endPoint: mapCommon.LatLng = { latitude: 39.9208, longitude: 32.8541 };
  private arcCenterPoint: mapCommon.LatLng = { latitude: 41.5000, longitude: 30.9000 };
  private tracePoints: Array<mapCommon.LatLng> = [
    { latitude: 39.9334, longitude: 32.8597 }, // Ankara
    { latitude: 41.0082, longitude: 28.9784 }, // İstanbul
    { latitude: 42.1500, longitude: 24.7500 }, // Filibe
    { latitude: 42.6977, longitude: 23.3219 }, // Sofya
    { latitude: 44.7866, longitude: 20.4489 }, // Belgrad
    { latitude: 45.8150, longitude: 15.9819 }, // Zagreb
    { latitude: 46.0569, longitude: 14.5058 }, // Ljubljana
    { latitude: 45.4408, longitude: 12.3155 }, // Venedik
    { latitude: 44.4056, longitude: 8.9463 }, // Genova
    { latitude: 43.7384, longitude: 7.4246 }// Monaco
  ];
  @State statusText: string = 'Welcome to Map Codelab';
  private isAnimating: boolean = false;
  private isFirstLoad: boolean = true;
  private idleTimeoutId: number = -1;


  aboutToAppear(): void {
    this.isFirstLoad=true
  }
  @Builder
  private arcButton(label: string, position: ArcButtonPosition, onClick: () => void) {
    ArcButton({
      options: new ArcButtonOptions({
        label,
        position,
        styleMode: ArcButtonStyleMode.EMPHASIZED_LIGHT,
        onClick
      })
    })
      .offset({ y: position === ArcButtonPosition.TOP_EDGE ? -4 : 4 })
  }

  build() {
    Stack() {
      MapComponent({
        mapOptions: {
          position: {
            target: { latitude: 42.0, longitude: 20.0 },
            zoom: 4
          }
        },
        mapCallback: (err: BusinessError, mapController: map.MapComponentController): void => {
          if (err) {
            this.statusText = `Error: ${err.message}`;
            return;
          }
          this.mapController = mapController;
          this.onMapReady();
        }
      })
        .width('100%')
        .height('100%')

      Column() {
        Text(this.statusText)
          .fontSize(11)
          .fontColor('#FFFFFF')
          .backgroundColor('#80000000')
          .padding({
            left: 10,
            right: 10,
            top: 4,
            bottom: 4
          })
          .borderRadius(12)
          .textAlign(TextAlign.Center)
          .margin({ top: 50 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Start)
      .hitTestBehavior(HitTestMode.Transparent)

      Column() {
        this.arcButton('Create Arc', ArcButtonPosition.TOP_EDGE, (): void => {
          this.addDemoArc();
        })

        Blank()

        this.arcButton('Create Route', ArcButtonPosition.BOTTOM_EDGE, (): void => {
          this.addDemoTrace();
        })
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
  }

  private onMapReady(): void {
    if (!this.mapController) {
      return;
    }
    this.setupEventManager();
  }

  private setupEventManager(): void {
    if (!this.mapController) {
      return;
    }
    this.mapEventManager = this.mapController.getEventManager();

    this.mapEventManager.on('mapClick', (position: mapCommon.LatLng): void => {
      this.statusText = `${position.latitude.toFixed(3)}, ${position.longitude.toFixed(3)}`;
    });

    this.mapEventManager.on('mapLongClick', (): void => {
      this.clearMap();

    });

    this.mapEventManager.on('markerDragEnd', (): void => {
      console.info('dragEnd');

    });
    this.mapEventManager.on('markerClick', (): void => {
      console.info('dragClick');

    });

    this.mapEventManager.on('markerDrag', (): void => {
      console.info('drag');

    });
    this.mapEventManager.on('markerDragStart', (): void => {
      console.info('dragstart');
    });

    this.mapEventManager.on('cameraMoveStart', () => {

      if (this.idleTimeoutId !== -1) {
        clearTimeout(this.idleTimeoutId);
        this.idleTimeoutId = -1;
      }

      if (this.isFirstLoad || this.isAnimating) {
        return
      };
      this.statusText = 'Camera move started';

    });

    this.mapEventManager.on('cameraMove', () => {   
      if (this.isFirstLoad || this.isAnimating) {
        return
      };
      this.statusText = 'Camera is moving';
      this.isFirstLoad=false

    });

    this.mapEventManager.on('cameraIdle', () => {
      if (this.isFirstLoad) {
        this.isFirstLoad = false;
        return;
      }

      if (this.isAnimating) {
        return
      };

      this.statusText = 'Camera stopped';

      this.idleTimeoutId = setTimeout(() => {
        if (this.statusText === 'Camera stopped') {
          this.statusText = 'LongPress to Clear Map';
        }
      }, 3000);

    });
  }

  private async addDemoArc(): Promise<void> {
    if (!this.mapController) {
      return;
    }
    this.statusText = 'İstanbul - Ankara arc drawing...';

    let bounds: mapCommon.LatLngBounds = map.LatLngBoundsUtils.include(this.startPoint);
    bounds = map.LatLngBoundsUtils.include(this.endPoint, bounds);
    bounds = map.LatLngBoundsUtils.include(this.arcCenterPoint, bounds);

    const cameraUpdate: map.CameraUpdate = map.newLatLngBounds(bounds, 50);
    await this.mapController.animateCamera(cameraUpdate, 1000);

    const arcParams: mapCommon.MapArcParams = {
      startPoint: this.startPoint,
      endPoint: this.endPoint,
      centerPoint: this.arcCenterPoint,
      width: 10,
      color: 0xffff0000,
      visible: true,
      zIndex: 100
    };
    await this.mapController.addArc(arcParams);
    this.statusText = 'İst-Ank Arc added';
  }

  private async addDemoTrace(): Promise<void> {
    this.isAnimating = true
    if (!this.mapController) {
      return;
    }
    this.statusText = 'Europe route is focusing..';

    let europeBounds: mapCommon.LatLngBounds = map.LatLngBoundsUtils.include(this.tracePoints[0]);
    for (let i = 1; i < this.tracePoints.length; i++) {
      europeBounds = map.LatLngBoundsUtils.include(this.tracePoints[i], europeBounds);
    }

    const cameraUpdate: map.CameraUpdate = map.newLatLngBounds(europeBounds, 40);
    this.mapController.animateCamera(cameraUpdate, 1200);

    const idleMarker: map.Marker = await this.mapController.addMarker({
      position: this.tracePoints[0],
      anchorU: 0.5,
      anchorV: 1,
      visible: true
    });

    const movingMarker: map.Marker = await this.mapController.addMarker({
      position: this.tracePoints[0],
      anchorU: 0.5,
      anchorV: 1,
      visible: false
    });

    const traceOptions: mapCommon.TraceOverlayParams = {
      points: this.tracePoints,
      animationDuration: 8000,
      isMapMoving: false,
      color: 0xFF00AAFF,
      width: 12,
      animationCallback: (pointIndex: number): void => {
        if (pointIndex === 4) {
          idleMarker.setVisible(false);
          movingMarker.setVisible(true);
        } else if (pointIndex === 9) {
          this.isAnimating = false
          this.statusText = 'Route end'
          this.idleTimeoutId = setTimeout(() => {
            if (this.statusText === 'Route end') {
              this.statusText = 'LongPress to Clear Map';
            }
          }, 3000);
        }
      }
    };

    const markers: Array<map.Marker> = [idleMarker, movingMarker];

    const startDelayId: number = setTimeout(async (): Promise<void> => {
      if (this.mapController) {
        this.statusText = 'Ankara -> Monaco route in progress...';
        try {
          await this.mapController.addTraceOverlay(traceOptions, markers);
        } catch (error) {
          console.info(error)
        }
      }
    }, 1400);
  }

  private clearMap(): void {
    if (!this.mapController) {
      return;
    }
    this.mapController.clear();
    this.statusText = 'Map Cleared';



    this.idleTimeoutId = setTimeout(() => {
      if (this.statusText === 'Map Cleared') {
        this.statusText = 'Welcome to Map Codelab';
      }
    }, 3000);
  }
}