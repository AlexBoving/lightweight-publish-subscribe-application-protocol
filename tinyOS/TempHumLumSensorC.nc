generic configuration TempHumLumSensorC()
{
	provides interface Read<uint16_t> as TempRead;
	provides interface Read<uint16_t> as HumRead;
	provides interface Read<uint16_t> as LumRead;
}
implementation
{
	components MainC;
	components new TempHumLumSensorP();
	components new TimerMilliC() as ReadTempTimer;
	components new TimerMilliC() as ReadHumTimer;
	components new TimerMilliC() as ReadLumTimer;

	// Connects the provided interface

	TempRead = TempHumLumSensorP.TempRead;
	HumRead = TempHumLumSensorP.HumRead;
	LumRead = TempHumLumSensorP.LumRead;

	// Timer interface

	TempHumLumSensorP.TimerReadTemp->ReadTempTimer;
	TempHumLumSensorP.TimerReadHum->ReadHumTimer;
	TempHumLumSensorP.TimerReadLum->ReadLumTimer;
}